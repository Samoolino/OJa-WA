module Spree
  module Checkout
    class AllocationAuthorizationCommand
      Result = Struct.new(:allowed, :reason, :allocation, :ledger_entry, :amount_minor, :currency, keyword_init: true)

      def self.call(allocation:, amount_minor:, idempotency_key:, correlation_id:, context:)
        new(allocation:, amount_minor:, idempotency_key:, correlation_id:, context:).call
      end

      def initialize(allocation:, amount_minor:, idempotency_key:, correlation_id:, context:)
        @allocation = allocation
        @amount_minor = Integer(amount_minor)
        @idempotency_key = idempotency_key.to_s
        @correlation_id = correlation_id.to_s
        @context = context.deep_symbolize_keys
      end

      def call
        validate!
        geo_result = evaluate_geography
        return rejected(geo_result.reason) unless geo_result.allowed

        authorization = Spree::AllocationAuthorization.reserve!(
          allocation: @allocation,
          amount_minor: @amount_minor,
          operation_id: "allocation-reservation:#{@idempotency_key}",
          idempotency_key: @idempotency_key,
          correlation_id: @correlation_id,
          context: @context.merge(geo_evidence: geo_result.evidence)
        )

        Result.new(
          allowed: authorization.allowed,
          reason: authorization.reason,
          allocation: authorization.allocation,
          ledger_entry: authorization.ledger_entry,
          amount_minor: @amount_minor,
          currency: authorization.allocation.currency
        )
      end

      private

      def validate!
        raise ArgumentError, "amount_minor must be greater than zero" unless @amount_minor.positive?
        raise ArgumentError, "idempotency_key is required" if @idempotency_key.blank?
        raise ArgumentError, "correlation_id is required" if @correlation_id.blank?
        raise ArgumentError, "vendor_id is required" if @context[:vendor_id].blank?
        raise ArgumentError, "store_id is required" if @context[:store_id].blank?
        raise ArgumentError, "product_id is required" if @context[:product_id].blank?
      end

      def evaluate_geography
        policy = @allocation.policy || {}
        geo_policy = policy["geo_policy"] || @allocation.metadata.to_h["geo_policy"] || {}
        return OpenStruct.new(allowed: true, reason: "no_geo_restriction", evidence: {}) if geo_policy.blank?

        latitude = @context[:latitude] || @context[:geo_context].to_h[:latitude]
        longitude = @context[:longitude] || @context[:geo_context].to_h[:longitude]
        return OpenStruct.new(allowed: false, reason: "geo_coordinates_required", evidence: {}) if latitude.blank? || longitude.blank?

        hierarchy = Spree::NestedGeographyResolver.call(
          latitude: latitude,
          longitude: longitude,
          country_code: @context[:country_code] || @context[:geo_context].to_h[:country_code]
        )
        unless hierarchy.consistent
          return OpenStruct.new(allowed: false, reason: hierarchy.reason, evidence: { "hierarchy" => hierarchy.matches })
        end

        geo_context = (@context[:geo_context] || {}).deep_stringify_keys.merge(
          "latitude" => latitude,
          "longitude" => longitude,
          "store_id" => @context[:store_id].to_s,
          "country_code" => @context[:country_code] || hierarchy.matches.dig("country", 0, "code"),
          "state_code" => @context[:state_code] || hierarchy.matches.dig("state", 0, "code"),
          "lga_code" => @context[:lga_code] || hierarchy.matches.dig("lga", 0, "code"),
          "zone_code" => @context[:zone_code] || hierarchy.matches.dig("zone", 0, "code")
        ).compact

        result = Spree::GeoPolicyEngine.evaluate(policy: geo_policy, geo_context: geo_context)
        OpenStruct.new(
          allowed: result.allowed,
          reason: result.reason,
          evidence: result.evidence.merge("hierarchy" => hierarchy.matches)
        )
      end

      def rejected(reason)
        Result.new(allowed: false, reason:, allocation: @allocation, amount_minor: @amount_minor, currency: @allocation.currency)
      end
    end
  end
end
