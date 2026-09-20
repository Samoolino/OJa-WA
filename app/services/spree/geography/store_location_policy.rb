module Spree
  module Geography
    class StoreLocationPolicy
      Result = Struct.new(:allowed, :reason, keyword_init: true)

      def self.evaluate(store:, context:)
        new(store:, context: context.deep_symbolize_keys).evaluate
      end

      def initialize(store:, context:)
        @store = store
        @context = context
      end

      def evaluate
        return Result.new(allowed: false, reason: "store_blocked") if @store.blocked?

        expected = @store.policy || {}
        return Result.new(allowed: true, reason: "geography_not_restricted") if expected.empty?

        if expected["country_code"].present? &&
           expected["country_code"].to_s.upcase != @context[:country_code].to_s.upcase
          return Result.new(allowed: false, reason: "country_mismatch")
        end

        if expected["admin_area_1_code"].present? &&
           expected["admin_area_1_code"].to_s.casecmp?(@context[:admin_area_1_code].to_s) == false
          return Result.new(allowed: false, reason: "admin_area_1_mismatch")
        end

        if expected["admin_area_2_code"].present? &&
           expected["admin_area_2_code"].to_s.casecmp?(@context[:admin_area_2_code].to_s) == false
          return Result.new(allowed: false, reason: "admin_area_2_mismatch")
        end

        if expected["locality"].present? &&
           expected["locality"].to_s.casecmp?(@context[:locality].to_s) == false
          return Result.new(allowed: false, reason: "locality_mismatch")
        end

        Result.new(allowed: true, reason: "geography_match")
      end
    end
  end
end
