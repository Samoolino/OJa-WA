module Spree
  module Checkout
    class PaymentOrchestrationCommand
      Result = Struct.new(:status, :reason, :amount_minor, :currency, :allocation, :ledger_entry, keyword_init: true)

      def self.call(allocation:, line_items:, context:, idempotency_key:, correlation_id:)
        new(allocation:, line_items:, context:, idempotency_key:, correlation_id:).call
      end

      def initialize(allocation:, line_items:, context:, idempotency_key:, correlation_id:)
        @allocation = allocation
        @line_items = Array(line_items)
        @context = context.deep_symbolize_keys
        @idempotency_key = idempotency_key.to_s
        @correlation_id = correlation_id.to_s
      end

      def call
        basket = Spree::Checkout::ExactBasketEvaluator.call(
          allocation: @allocation,
          line_items: @line_items,
          context: @context
        )
        return Result.new(status: "REJECTED", reason: basket.reason, amount_minor: basket.amount_minor, currency: basket.currency) unless basket.allowed

        authorization = Spree::Checkout::AllocationAuthorizationCommand.call(
          allocation: @allocation,
          amount_minor: basket.amount_minor,
          idempotency_key: @idempotency_key,
          correlation_id: @correlation_id,
          context: @context.merge(purpose: @context[:purpose])
        )

        Result.new(
          status: authorization.allowed ? "AUTHORIZED_FOR_PAYMENT" : "REJECTED",
          reason: authorization.reason,
          amount_minor: authorization.amount_minor,
          currency: authorization.currency,
          allocation: authorization.allocation,
          ledger_entry: authorization.ledger_entry
        )
      end
    end
  end
end
