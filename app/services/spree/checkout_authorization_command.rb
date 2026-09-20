module Spree
  module Checkout
    class AuthorizationCommand
      Result = Struct.new(:authorized, :reason, :allocation, :geo_evidence, keyword_init: true)

      def self.call(allocation:, amount_minor:, currency:, vendor_store_id:, product_skus:, geo_context:, correlation_id:)
        new(allocation:, amount_minor:, currency:, vendor_store_id:, product_skus:, geo_context:, correlation_id:).call
      end

      def initialize(**attrs)
        @allocation = attrs[:allocation]
        @amount_minor = Integer(attrs[:amount_minor])
        @currency = attrs[:currency].to_s.upcase
        @vendor_store_id = attrs[:vendor_store_id]
        @product_skus = Array(attrs[:product_skus]).map(&:to_s)
        @geo_context = attrs[:geo_context] || {}
        @correlation_id = attrs[:correlation_id].to_s
      end

      def call
        return deny("correlation_id_required") if @correlation_id.blank?
        return deny("invalid_amount") if @amount_minor <= 0
        return deny("currency_mismatch") unless @allocation.currency.to_s.upcase == @currency
        return deny("allocation_inactive") unless @allocation.active?
        return deny("insufficient_available_allocation") if @allocation.available_minor < @amount_minor
        return deny("vendor_store_not_allowed") unless vendor_store_allowed?
        return deny("product_policy_rejected") unless products_allowed?

        geo = Spree::GeoPolicyEngine.evaluate(policy: @allocation.metadata.fetch("geo_policy", {}), geo_context: @geo_context)
        return deny(geo.reason) unless geo.allowed

        Spree::AllocationLedgerCommand.call(
          allocation: @allocation,
          entry_type: "reserve",
          amount_minor: @amount_minor,
          operation_id: "allocation-reserve:#{@correlation_id}",
          idempotency_key: "allocation-reserve:#{@correlation_id}",
          correlation_id: @correlation_id,
          metadata: { vendor_store_id: @vendor_store_id, product_skus: @product_skus, geo_evidence: geo.evidence }
        )

        Result.new(authorized: true, reason: "allocation_reserved", allocation: @allocation, geo_evidence: geo.evidence)
      rescue ArgumentError => e
        deny(e.message)
      end

      private

      def deny(reason)
        Result.new(authorized: false, reason:, allocation: @allocation)
      end

      def vendor_store_allowed?
        policy = @allocation.metadata.fetch("vendor_store_policy", {})
        allowed = Array(policy["store_ids"] || policy[:store_ids])
        allowed.empty? || allowed.map(&:to_s).include?(@vendor_store_id.to_s)
      end

      def products_allowed?
        policy = @allocation.metadata.fetch("product_policy", {})
        blocked = Array(policy["blocked_skus"] || policy[:blocked_skus]).map(&:to_s)
        required = Array(policy["allowed_skus"] || policy[:allowed_skus]).map(&:to_s)
        return false if @product_skus.any? { |sku| blocked.include?(sku) }
        required.empty? || @product_skus.all? { |sku| required.include?(sku) }
      end
    end
  end
end
