module Spree
  module Checkout
    class ExactBasketEvaluator
      Result = Struct.new(:allowed, :reason, :amount_minor, :currency, :line_items, keyword_init: true)

      def self.call(allocation:, line_items:, context:)
        new(allocation:, line_items:, context: context.deep_symbolize_keys).call
      end

      def initialize(allocation:, line_items:, context:)
        @allocation = allocation
        @line_items = Array(line_items)
        @context = context
      end

      def call
        return Result.new(allowed: false, reason: "empty_basket") if @line_items.empty?

        amount_minor = @line_items.sum { |item| Integer(item.fetch(:amount_minor)) }
        return Result.new(allowed: false, reason: "invalid_basket_amount") unless amount_minor.positive?

        products = @line_items.map { |item| item.fetch(:product_id).to_s }
        policy = @allocation.policy || {}

        if policy["product_ids"].present?
          allowed_products = Array(policy["product_ids"]).map(&:to_s)
          return Result.new(allowed: false, reason: "product_mismatch", amount_minor:, currency: @allocation.currency) unless products.all? { |id| allowed_products.include?(id) }
        end

        geo = Spree::Geography::StoreLocationPolicy.evaluate(
          store: @context.fetch(:store),
          context: @context
        )
        return Result.new(allowed: false, reason: geo.reason, amount_minor:, currency: @allocation.currency) unless geo.allowed

        Result.new(
          allowed: true,
          reason: "basket_policy_match",
          amount_minor:,
          currency: @allocation.currency,
          line_items: @line_items
        )
      rescue KeyError, TypeError, ArgumentError
        Result.new(allowed: false, reason: "invalid_basket")
      end
    end
  end
end
