module Spree
  module Fulfillment
    class Create
      prepend Spree::ServiceModule::Base

      def call(order_id:, vendor_reference:, mode:, idempotency_key:, correlation_id:, tracking_reference: nil)
        raise ArgumentError, "order_id is required" unless order_id
        raise ArgumentError, "vendor_reference is required" if vendor_reference.blank?
        raise ArgumentError, "invalid fulfillment mode" unless Spree::OrderFulfillment::MODES.include?(mode.to_s)
        raise ArgumentError, "idempotency_key is required" if idempotency_key.blank?
        raise ArgumentError, "correlation_id is required" if correlation_id.blank?

        fulfillment = Spree::OrderFulfillment.find_or_create_by!(idempotency_key: idempotency_key.to_s) do |record|
          record.order_id = order_id
          record.vendor_reference = vendor_reference
          record.fulfillment_mode = mode.to_s
          record.status = "pending"
          record.tracking_reference = tracking_reference
          record.correlation_id = correlation_id
        end
        success(fulfillment: fulfillment)
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end
    end
  end
end
