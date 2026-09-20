module Spree
  module Allocation
    class Release
      prepend Spree::ServiceModule::Base
      def call(plan_allocation:, amount_cents:, currency:, idempotency_key:, correlation_id:, source_reference:, metadata: {})
        Spree::Allocation::LedgerOperation.new.call(
          plan_allocation: plan_allocation, amount_cents: amount_cents, currency: currency,
          operation: "release", idempotency_key: idempotency_key, correlation_id: correlation_id,
          source_type: "reservation_release", source_reference: source_reference, metadata: metadata
        )
      end
    end
  end
end
