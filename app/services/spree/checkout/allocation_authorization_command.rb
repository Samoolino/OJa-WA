module Spree
  module Checkout
    class AllocationAuthorizationCommand
      Result = Struct.new(:allowed, :reason, :allocation, :ledger_entry, :amount_minor, :currency, keyword_init: true)

      def self.call(allocation:, amount_minor:, idempotency_key:, correlation_id:, context:)
        new(allocation:, amount_minor:, idempotency_key:, correlation_id:, context:).call
      end

      def initialize(allocation:, amount_minor:, idempotency_key:, correlation_id:, context:)
        @allocation = allocation
        @amount_minor = Integer(amount_minor)
        @idempotency_key = idempotency_key.to_s
        @correlation_id = correlation_id.to_s
        @context = context.deep_symbolize_keys
      end

      def call
        validate!
        authorization = Spree::AllocationAuthorization.reserve!(
          allocation: @allocation,
          amount_minor: @amount_minor,
          operation_id: "allocation-reservation:#{@idempotency_key}",
          idempotency_key: @idempotency_key,
          correlation_id: @correlation_id,
          context: @context
        )

        Result.new(
          allowed: authorization.allowed,
          reason: authorization.reason,
          allocation: authorization.allocation,
          ledger_entry: authorization.ledger_entry,
          amount_minor: @amount_minor,
          currency: authorization.allocation.currency
        )
      end

      private

      def validate!
        raise ArgumentError, "amount_minor must be greater than zero" unless @amount_minor.positive?
        raise ArgumentError, "idempotency_key is required" if @idempotency_key.blank?
        raise ArgumentError, "correlation_id is required" if @correlation_id.blank?
        raise ArgumentError, "vendor_id is required" if @context[:vendor_id].blank?
        raise ArgumentError, "store_id is required" if @context[:store_id].blank?
        raise ArgumentError, "product_id is required" if @context[:product_id].blank?
      end
    end
  end
end
