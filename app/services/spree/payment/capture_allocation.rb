module Spree
  module Payment
    class CaptureAllocation
      prepend Spree::ServiceModule::Base

      def call(plan_allocation:, user:, amount_cents:, currency:, provider:, provider_event_id:,
               payment_payload:, reserve_idempotency_key:, capture_idempotency_key:, correlation_id:)
        ActiveRecord::Base.transaction do
          allocation = Spree::PlanAllocation.lock.find(plan_allocation.id)
          return failure(errors: ['beneficiary mismatch']) unless allocation.user_id.nil? || allocation.user_id == user.id
          return failure(errors: ['currency mismatch']) unless allocation.currency == currency
          reserve = Spree::AllocationLedgerEntry.find_by(idempotency_key: reserve_idempotency_key)
          return failure(errors: ['reservation not found']) unless reserve&.entry_type == 'reserve'

          evidence_result = Spree::Payment::EvidenceIngestion.new.call(
            plan_allocation: allocation, provider: provider, provider_event_id: provider_event_id,
            amount_cents: amount_cents, currency: currency, payload: payment_payload,
            idempotency_key: capture_idempotency_key, correlation_id: correlation_id
          )
          return evidence_result unless evidence_result.success?

          evidence = evidence_result.evidence
          reconciliation = Spree::Reconciliation::Compare.new.call(
            plan_allocation: allocation, expected_amount_cents: amount_cents,
            expected_currency: currency, observed_amount_cents: evidence.amount_cents,
            observed_currency: evidence.currency, evidence_id: evidence.id,
            idempotency_key: "reconcile:#{capture_idempotency_key}",
            correlation_id: correlation_id
          )
          return reconciliation unless reconciliation.success? && reconciliation.matched

          result = Spree::Allocation::LedgerOperation.new.call(
            plan_allocation: allocation, amount_cents: amount_cents, currency: currency,
            operation: 'consume', idempotency_key: capture_idempotency_key,
            correlation_id: correlation_id, source_type: 'payment',
            source_reference: provider_event_id, metadata: { provider: provider }
          )
          return result unless result.success?

          success(allocation: result.allocation, evidence: evidence,
                  reconciliation: reconciliation.record, ledger_entry: result.ledger_entry)
        end
      end
    end
  end
end
