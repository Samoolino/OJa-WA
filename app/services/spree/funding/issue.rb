module Spree
  module Funding
    class Issue
      prepend Spree::ServiceModule::Base

      def call(plan_allocation:, amount_cents:, currency:, source_type:, source_reference:,
               provider:, status:, idempotency_key:, correlation_id:, evidence: {})
        raise ArgumentError, 'amount_cents must be positive' unless amount_cents.to_i > 0
        raise ArgumentError, 'currency must be 3 letters' unless currency.to_s.match?(/\A[A-Z]{3}\z/)
        raise ArgumentError, 'idempotency_key is required' if idempotency_key.blank?
        raise ArgumentError, 'correlation_id is required' if correlation_id.blank?
        raise ArgumentError, 'funding status must be verified' unless status.to_s == 'verified'

        ActiveRecord::Base.transaction do
          allocation = Spree::PlanAllocation.lock.find(plan_allocation.id)
          prior = Spree::AllocationLedgerEntry.find_by(idempotency_key: idempotency_key)
          return success(allocation: allocation, ledger_entry: prior, replay: true) if prior

          ingress = Spree::FundingIngress.create!(
            plan_allocation: allocation,
            source_type: source_type,
            source_reference: source_reference,
            provider: provider,
            status: status,
            currency: currency,
            amount_cents: amount_cents,
            idempotency_key: idempotency_key,
            correlation_id: correlation_id,
            evidence: evidence,
            occurred_at: Time.current
          )

          ledger = Spree::AllocationLedgerEntry.create!(
            plan_allocation: allocation,
            entry_type: 'fund',
            amount_cents: amount_cents,
            currency: currency,
            idempotency_key: idempotency_key,
            correlation_id: correlation_id,
            source_type: 'funding_ingress',
            source_reference: ingress.id.to_s,
            metadata: { provider: provider, source_type: source_type },
            occurred_at: Time.current
          )

          allocation.funded_cents += amount_cents
          allocation.currency = currency
          Spree::Financial::Invariants.assert_non_negative!(allocation)
          allocation.save!
          success(allocation: allocation, ledger_entry: ledger, funding_ingress: ingress, replay: false)
        end
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end
    end
  end
end
