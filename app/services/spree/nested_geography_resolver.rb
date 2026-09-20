module Spree
  class NestedGeographyResolver
    LEVELS = %w[country state region lga district zone store].freeze
    Result = Struct.new(:consistent, :reason, :matches, keyword_init: true)

    def self.call(latitude:, longitude:, country_code: nil)
      new(latitude:, longitude:, country_code:).call
    end

    def initialize(latitude:, longitude:, country_code: nil)
      @latitude = Float(latitude)
      @longitude = Float(longitude)
      @country_code = country_code.presence
    end

    def call
      return Result.new(consistent: false, reason: "invalid_coordinates", matches: {}) unless valid_coordinates?

      point = "ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography"
      relation = Spree::GeographicBoundary.where("ST_Covers(boundary, #{point})", @longitude, @latitude)
      relation = relation.where(country_code: @country_code) if @country_code

      rows = relation.order(Arel.sql("CASE level WHEN 'country' THEN 1 WHEN 'state' THEN 2 WHEN 'region' THEN 3 WHEN 'lga' THEN 4 WHEN 'district' THEN 5 WHEN 'zone' THEN 6 WHEN 'store' THEN 7 ELSE 99 END"))
                    .pluck(:code, :name, :level, :parent_code, :country_code)

      matches = {}
      rows.each do |code, name, level, parent_code, country_code|
        matches[level] ||= []
        matches[level] << { "code" => code, "name" => name, "parent_code" => parent_code, "country_code" => country_code }
      end

      consistency = hierarchy_consistent?(matches)
      Result.new(
        consistent: consistency,
        reason: consistency ? "nested_geography_resolved" : "nested_geography_inconsistent",
        matches:
      )
    rescue ArgumentError, TypeError
      Result.new(consistent: false, reason: "invalid_coordinates", matches: {})
    end

    private

    def valid_coordinates?
      @latitude.between?(-90.0, 90.0) && @longitude.between?(-180.0, 180.0)
    end

    def hierarchy_consistent?(matches)
      return false if matches.empty?

      present_levels = LEVELS.select { |level| matches[level].present? }
      return false unless present_levels.all? { |level| matches[level].one? }

      present_levels.each_cons(2).all? do |parent_level, child_level|
        parent = matches[parent_level].first
        children = matches[child_level]
        children.all? { |entry| entry["parent_code"].to_s == parent["code"].to_s }
      end
    end
  end
end
