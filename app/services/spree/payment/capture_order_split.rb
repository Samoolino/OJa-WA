module Spree
  module Payment
    class CaptureOrderSplit
      prepend Spree::ServiceModule::Base

      def call(order_id:, split:, allocation:, user:, amount_cents:, currency:, provider:, provider_event_id:,
               payment_payload:, reserve_idempotency_key:, capture_idempotency_key:, fulfillment_mode:,
               fulfillment_idempotency_key:, settlement_idempotency_key:, platform_fee_cents: 0,
               line_items:, correlation_id:, vendor_account_ready: false, context: {})
        ActiveRecord::Base.transaction do
          order_split = Spree::OrderSplit.lock.find(split.id)
          basket = Spree::Checkout::ExactBasket.new.call(
            line_items: line_items, expected_amount_cents: amount_cents, currency: currency
          )
          return basket unless basket.success?
          return failure(errors: ["split amount mismatch"]) unless order_split.amount_cents == amount_cents
          return failure(errors: ["split currency mismatch"]) unless order_split.currency == currency.to_s.upcase

          capture = Spree::Payment::CaptureAllocation.new.call(
            plan_allocation: allocation, user: user, amount_cents: amount_cents, currency: currency,
            provider: provider, provider_event_id: provider_event_id, payment_payload: payment_payload,
            reserve_idempotency_key: reserve_idempotency_key, capture_idempotency_key: capture_idempotency_key,
            correlation_id: correlation_id
          )
          return capture unless capture.success?

          order_split.update!(status: "CAPTURED", payment_reference: provider_event_id,
                              fulfillment_status: "PENDING", correlation_id: correlation_id)

          fulfillment = Spree::Fulfillment::Create.new.call(
            order_id: order_id, vendor_reference: order_split.vendor_id.to_s,
            mode: fulfillment_mode, idempotency_key: fulfillment_idempotency_key,
            correlation_id: correlation_id
          )
          return fulfillment unless fulfillment.success?

          settlement = Spree::Settlement::Build.new.call(
            order_id: order_id, vendor_reference: order_split.vendor_id.to_s,
            currency: order_split.currency, gross_amount_cents: order_split.amount_cents,
            platform_fee_cents: platform_fee_cents, plan_allocation_id: allocation.id,
            correlation_id: correlation_id, idempotency_key: settlement_idempotency_key
          )
          return settlement unless settlement.success?

          transfer = Spree::Settlement::RequestTransfer.new.call(
            settlement: settlement.settlement, payment_captured: true,
            vendor_account_ready: vendor_account_ready, fulfillment_required: true,
            fulfillment_confirmed: fulfillment.fulfillment.status == "confirmed",
            reconciliation_status: capture.reconciliation.status,
            transfer_idempotency_key: settlement_idempotency_key,
            correlation_id: correlation_id
          )

          success(split: order_split, capture: capture, fulfillment: fulfillment.fulfillment,
                  settlement: settlement.settlement, transfer: transfer)
        end
      end
    end
  end
end
