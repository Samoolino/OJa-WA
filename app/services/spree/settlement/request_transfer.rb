module Spree
  module Settlement
    class RequestTransfer
      prepend Spree::ServiceModule::Base

      def call(settlement:, payment_captured:, vendor_account_ready:, fulfillment_required:, fulfillment_confirmed:, reconciliation_status:, transfer_idempotency_key:, correlation_id:)
        raise ArgumentError, "transfer_idempotency_key is required" if transfer_idempotency_key.blank?
        raise ArgumentError, "correlation_id is required" if correlation_id.blank?

        ActiveRecord::Base.transaction do
          record = Spree::SettlementRecord.lock.find(settlement.id)
          unless payment_captured && vendor_account_ready &&
                 (!fulfillment_required || fulfillment_confirmed) &&
                 reconciliation_status.to_s == "MATCHED"
            record.update!(status: "blocked") if record.status == "created"
            return failure(errors: ["settlement blocked"])
          end

          return success(settlement: record, replay: true) if record.status == "confirmed"

          record.status = "requested"
          record.idempotency_key = transfer_idempotency_key.to_s
          record.correlation_id = correlation_id.to_s
          record.save!
          success(settlement: record, replay: false)
        end
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end
    end
  end
end
