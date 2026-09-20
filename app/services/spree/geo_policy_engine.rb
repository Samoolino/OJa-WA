module Spree
  class GeoPolicyEngine
    Result = Struct.new(:allowed, :reason, :classification, :evidence, keyword_init: true)

    LEVELS = %w[country state region lga district zone store].freeze

    def self.evaluate(policy:, geo_context:)
      new(policy:, geo_context:).evaluate
    end

    def initialize(policy:, geo_context:)
      @policy = policy || {}
      @geo = geo_context || {}
    end

    def evaluate
      return Result.new(allowed: true, reason: "no_geo_restriction", classification: nil, evidence: {}) if @policy.blank?

      classification = @policy["classification"].to_s
      return deny("invalid_geographic_classification") unless LEVELS.include?(classification)

      if @policy["geohashes"].present?
        return deny("geohash_not_permitted") unless Array(@policy["geohashes"]).map(&:to_s).include?(@geo["geohash"].to_s)
      end

      if @policy["country_codes"].present?
        return deny("country_not_permitted") unless Array(@policy["country_codes"]).map { |v| v.to_s.upcase }.include?(@geo["country_code"].to_s.upcase)
      end

      if @policy["state_codes"].present?
        return deny("state_not_permitted") unless Array(@policy["state_codes"]).map(&:to_s).include?(@geo["state_code"].to_s)
      end

      if @policy["lga_codes"].present?
        return deny("lga_not_permitted") unless Array(@policy["lga_codes"]).map(&:to_s).include?(@geo["lga_code"].to_s)
      end

      if @policy["store_ids"].present?
        return deny("store_not_permitted") unless Array(@policy["store_ids"]).map(&:to_s).include?(@geo["store_id"].to_s)
      end

      evidence = {
        classification:,
        country_code: @geo["country_code"],
        state_code: @geo["state_code"],
        lga_code: @geo["lga_code"],
        zone_code: @geo["zone_code"],
        store_id: @geo["store_id"],
        geohash: @geo["geohash"],
        latitude: @geo["latitude"],
        longitude: @geo["longitude"]
      }.compact

      Result.new(allowed: true, reason: "geo_policy_matched", classification:, evidence:)
    end

    private

    def deny(reason)
      Result.new(allowed: false, reason:, classification: @policy["classification"], evidence: @geo)
    end
  end
end
