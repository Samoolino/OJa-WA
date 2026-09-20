module Spree
  module Checkout
    class ExactBasket
      prepend Spree::ServiceModule::Base

      def call(line_items:, expected_amount_cents:, currency:)
        items = Array(line_items)
        total = items.sum do |item|
          quantity = Integer(item[:quantity] || item["quantity"] || 1)
          unit = Integer(item[:unit_price_cents] || item["unit_price_cents"])
          raise ArgumentError, "invalid basket line" if quantity <= 0 || unit < 0
          quantity * unit
        end
        return failure(errors: ["basket amount mismatch"]) unless total == Integer(expected_amount_cents)
        return failure(errors: ["basket is empty"]) if items.empty?
        success(total_cents: total, currency: currency.to_s.upcase)
      rescue ArgumentError, TypeError
        failure(errors: ["invalid basket"])
      end
    end
  end
end
