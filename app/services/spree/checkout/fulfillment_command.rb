module Spree
  module Checkout
    class FulfillmentCommand
      STATUSES = %w[CONFIRMED FAILED].freeze

      def self.call(split:, status:, idempotency_key:, correlation_id:, metadata: {})
        new(split:, status:, idempotency_key:, correlation_id:, metadata:).call
      end

      def initialize(split:, status:, idempotency_key:, correlation_id:, metadata:)
        @split = split
        @status = status.to_s
        @idempotency_key = idempotency_key.to_s
        @correlation_id = correlation_id.to_s
        @metadata = metadata
      end

      def call
        raise ArgumentError, "invalid fulfillment status" unless STATUSES.include?(@status)
        raise ArgumentError, "idempotency_key is required" if @idempotency_key.blank?
        raise ArgumentError, "correlation_id is required" if @correlation_id.blank?

        ActiveRecord::Base.transaction(requires_new: true) do
          split = Spree::CheckoutOrderSplit.lock.find(@split.id)
          prior = split.metadata["fulfillment_operation_id"]
          return split if prior == @idempotency_key

          split.fulfillment_status = @status
          split.metadata = split.metadata.merge(
            "fulfillment_operation_id" => @idempotency_key,
            "fulfillment_correlation_id" => @correlation_id,
            "fulfillment_metadata" => @metadata
          )
          split.save!
          split
        end
      end
    end
  end
end
