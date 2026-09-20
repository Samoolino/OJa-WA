module Spree
  module Settlement
    class Build
      prepend Spree::ServiceModule::Base

      def call(order_id:, vendor_reference:, currency:, gross_amount_cents:, platform_fee_cents:, plan_allocation_id:, correlation_id:, idempotency_key:)
        raise ArgumentError, "idempotency_key is required" if idempotency_key.blank?
        raise ArgumentError, "correlation_id is required" if correlation_id.blank?
        gross = Integer(gross_amount_cents)
        fee = Integer(platform_fee_cents)
        raise ArgumentError, "invalid settlement amounts" if gross.negative? || fee.negative? || fee > gross

        settlement = Spree::SettlementRecord.find_or_create_by!(idempotency_key: idempotency_key.to_s) do |record|
          record.order_id = order_id
          record.vendor_reference = vendor_reference.to_s
          record.currency = currency.to_s.upcase
          record.gross_amount_cents = gross
          record.platform_fee_cents = fee
          record.net_amount_cents = gross - fee
          record.plan_allocation_id = plan_allocation_id
          record.correlation_id = correlation_id.to_s
          record.status = "created"
        end
        success(settlement: settlement)
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end
    end
  end
end
