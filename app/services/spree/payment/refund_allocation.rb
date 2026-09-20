module Spree
  module Payment
    class RefundAllocation
      prepend Spree::ServiceModule::Base

      def call(plan_allocation:, user:, amount_cents:, currency:, refund_idempotency_key:, correlation_id:, source_reference:, metadata: {})
        ActiveRecord::Base.transaction do
          allocation = Spree::PlanAllocation.lock.find(plan_allocation.id)
          return failure(errors: ["beneficiary mismatch"]) unless allocation.user_id.nil? || allocation.user_id == user.id
          return failure(errors: ["currency mismatch"]) unless allocation.currency == currency

          result = Spree::Allocation::LedgerOperation.new.call(
            plan_allocation: allocation, amount_cents: amount_cents, currency: currency,
            operation: "reverse", idempotency_key: refund_idempotency_key,
            correlation_id: correlation_id, source_type: "refund",
            source_reference: source_reference, metadata: metadata
          )
          return result unless result.success?

          success(allocation: result.allocation, ledger_entry: result.ledger_entry, replay: result.replay)
        end
      end
    end
  end
end
