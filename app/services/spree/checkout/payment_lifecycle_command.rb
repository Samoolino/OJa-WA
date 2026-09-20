module Spree
  module Checkout
    class PaymentLifecycleCommand
      TRANSITIONS = {
        "AUTHORIZED" => %w[CAPTURED FAILED CANCELLED],
        "CAPTURED" => %w[SETTLED REFUNDED DISPUTED],
        "SETTLED" => %w[REFUNDED DISPUTED],
        "PROCESSING" => %w[AUTHORIZED CAPTURED FAILED CANCELLED],
        "REQUIRES_METHOD" => %w[PROCESSING CANCELLED],
        "REQUIRES_AUTH" => %w[PROCESSING AUTHORIZED FAILED CANCELLED]
      }.freeze

      def self.call(split:, target_status:, idempotency_key:, correlation_id:, allocation: nil, amount_minor: nil, metadata: {})
        new(split:, target_status:, idempotency_key:, correlation_id:, allocation:, amount_minor:, metadata:).call
      end

      def initialize(split:, target_status:, idempotency_key:, correlation_id:, allocation:, amount_minor:, metadata:)
        @split = split
        @target_status = target_status.to_s
        @idempotency_key = idempotency_key.to_s
        @correlation_id = correlation_id.to_s
        @allocation = allocation
        @amount_minor = amount_minor
        @metadata = metadata
      end

      def call
        raise ArgumentError, "idempotency_key is required" if @idempotency_key.blank?
        raise ArgumentError, "correlation_id is required" if @correlation_id.blank?

        current = @split.status
        allowed = TRANSITIONS.fetch(current, []).include?(@target_status)
        raise ArgumentError, "invalid payment transition" unless allowed

        ActiveRecord::Base.transaction(requires_new: true) do
          split = Spree::CheckoutOrderSplit.lock.find(@split.id)
          split.status = @target_status
          split.transfer_idempotency_key ||= "transfer:#{@idempotency_key}" if @target_status == "CAPTURED"
          split.save!

          if @target_status == "CAPTURED" && @allocation
            Spree::AllocationLedgerCommand.call(
              allocation: @allocation,
              entry_type: "consume",
              amount_minor: Integer(@amount_minor || split.amount_minor),
              operation_id: "allocation-consume:#{@idempotency_key}",
              idempotency_key: "allocation-consume:#{@idempotency_key}",
              correlation_id: @correlation_id,
              metadata: @metadata.merge(payment_status: @target_status, order_reference: split.order_reference)
            )
          end

          if @target_status == "CANCELLED" && @allocation
            Spree::AllocationLedgerCommand.call(
              allocation: @allocation,
              entry_type: "release",
              amount_minor: Integer(@amount_minor || split.amount_minor),
              operation_id: "allocation-release:#{@idempotency_key}",
              idempotency_key: "allocation-release:#{@idempotency_key}",
              correlation_id: @correlation_id,
              metadata: @metadata.merge(payment_status: @target_status, order_reference: split.order_reference)
            )
          end

          split
        end
      end
    end
  end
end
