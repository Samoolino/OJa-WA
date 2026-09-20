module Spree
  module Checkout
    class SettlementTransferCommand
      Result = Struct.new(:status, :reason, :split, keyword_init: true)

      def self.call(split:, idempotency_key:, correlation_id:)
        new(split:, idempotency_key:, correlation_id:).call
      end

      def initialize(split:, idempotency_key:, correlation_id:)
        @split = split
        @idempotency_key = idempotency_key.to_s
        @correlation_id = correlation_id.to_s
      end

      def call
        raise ArgumentError, "idempotency_key is required" if @idempotency_key.blank?
        raise ArgumentError, "correlation_id is required" if @correlation_id.blank?

        eligibility = Spree::Checkout::SettlementCommand.evaluate(split: @split)
        return Result.new(status: "BLOCKED", reason: eligibility.reason, split: eligibility.split) unless eligibility.eligible

        split = eligibility.split
        expected_key = split.transfer_idempotency_key.to_s
        return Result.new(status: "BLOCKED", reason: "transfer_identity_mismatch", split:) unless expected_key == @idempotency_key

        metadata = split.metadata || {}
        existing = metadata["transfer_request_status"]
        return Result.new(status: existing, reason: "idempotent_replay", split:) if existing.present?

        split.update!(
          metadata: metadata.merge(
            "transfer_request_status" => "REQUESTED",
            "transfer_request_correlation_id" => @correlation_id
          )
        )

        # Provider execution is deliberately absent. A certified payment adapter
        # consumes this request only after production gates are satisfied.
        Result.new(status: "REQUESTED", reason: "provider_execution_pending", split:)
      end
    end
  end
end
