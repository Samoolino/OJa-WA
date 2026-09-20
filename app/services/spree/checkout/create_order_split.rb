module Spree
  module Checkout
    class CreateOrderSplit
      prepend Spree::ServiceModule::Base
      def call(order_reference:, cart_reference:, vendor_id:, vendor_store_id:, currency:, line_items:, correlation_id:)
        raise ArgumentError, "correlation_id is required" if correlation_id.blank?
        basket = Spree::Checkout::ExactBasket.new.call(
          line_items: line_items,
          expected_amount_cents: Array(line_items).sum { |i| Integer(i[:quantity] || i["quantity"] || 1) * Integer(i[:unit_price_cents] || i["unit_price_cents"]) },
          currency: currency
        )
        return basket unless basket.success?

        total = basket.total_cents
        split = Spree::OrderSplit.create!(
          order_reference: order_reference, cart_reference: cart_reference,
          vendor_id: vendor_id, vendor_store_id: vendor_store_id,
          currency: currency.to_s.upcase, amount_cents: total,
          status: "AUTHORIZED", fulfillment_status: "PENDING",
          correlation_id: correlation_id, line_items: line_items
        )
        success(split: split)
      rescue ArgumentError, ActiveRecord::RecordInvalid => e
        failure(errors: [e.message])
      end
    end
  end
end
