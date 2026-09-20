module Spree
  module Checkout
    class RefundReversalCommand
      def self.call(allocation:, amount_minor:, idempotency_key:, correlation_id:, metadata: {})
        Spree::AllocationLedgerCommand.call(
          allocation:,
          entry_type: "reverse",
          amount_minor:,
          operation_id: "allocation-reverse:#{idempotency_key}",
          idempotency_key: "allocation-reverse:#{idempotency_key}",
          correlation_id:,
          metadata: metadata.merge("compensating_entry" => true, "reason" => "refund_or_reversal")
        )
      end
    end
  end
end
