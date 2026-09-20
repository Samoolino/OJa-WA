module Spree
  module Checkout
    class OrderSplitCommand
      Result = Struct.new(:created, :splits, :reason, keyword_init: true)

      def self.call(cart_reference:, order_reference:, line_items:, correlation_id:)
        new(cart_reference:, order_reference:, line_items:, correlation_id:).call
      end

      def initialize(cart_reference:, order_reference:, line_items:, correlation_id:)
        @cart_reference = cart_reference.to_s
        @order_reference = order_reference.to_s
        @line_items = Array(line_items)
        @correlation_id = correlation_id.to_s
      end

      def call
        validate!
        grouped = @line_items.group_by { |item| [item.fetch(:vendor_id).to_i, item[:store_id]&.to_i] }

        splits = grouped.map do |(vendor_id, store_id), items|
          vendor = Spree::Vendor.find(vendor_id)
          amount = items.sum { |item| Integer(item.fetch(:amount_minor)) }
          currency = items.map { |item| item.fetch(:currency).to_s }.uniq
          raise ArgumentError, "mixed currencies are not supported" unless currency.one?

          Spree::CheckoutOrderSplit.create!(
            cart_reference: @cart_reference,
            order_reference: @order_reference,
            vendor: vendor,
            vendor_store_id: store_id,
            currency: currency.first,
            amount_minor: amount,
            correlation_id: @correlation_id,
            line_items: items
          )
        end

        Result.new(created: true, splits:, reason: "order_split_created")
      end

      private

      def validate!
        raise ArgumentError, "cart_reference is required" if @cart_reference.blank?
        raise ArgumentError, "order_reference is required" if @order_reference.blank?
        raise ArgumentError, "correlation_id is required" if @correlation_id.blank?
        raise ArgumentError, "line_items are required" if @line_items.empty?
      end
    end
  end
end
