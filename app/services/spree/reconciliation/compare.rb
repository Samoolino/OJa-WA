module Spree
  module Reconciliation
    class Compare
      prepend Spree::ServiceModule::Base
      def call(plan_allocation:, expected_amount_cents:, expected_currency:, observed_amount_cents:, observed_currency:,
               evidence_id:, idempotency_key:, correlation_id:)
        status = if expected_currency != observed_currency
                   'CURRENCY_MISMATCH'
                 elsif expected_amount_cents.to_i != observed_amount_cents.to_i
                   'AMOUNT_MISMATCH'
                 else
                   'MATCHED'
                 end
        record = Spree::ReconciliationRecord.create!(
          plan_allocation: plan_allocation, expected_amount_cents: expected_amount_cents,
          expected_currency: expected_currency, observed_amount_cents: observed_amount_cents,
          observed_currency: observed_currency, status: status, evidence_id: evidence_id,
          idempotency_key: idempotency_key, correlation_id: correlation_id,
          compared_at: Time.current
        )
        success(record: record, matched: status == 'MATCHED')
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end
    end
  end
end
