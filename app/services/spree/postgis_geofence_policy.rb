module Spree
  class PostgisGeofencePolicy
    Result = Struct.new(:allowed, :reason, :boundary_codes, keyword_init: true)

    def self.evaluate(latitude:, longitude:, boundary_codes:)
      new(latitude:, longitude:, boundary_codes:).evaluate
    end

    def initialize(latitude:, longitude:, boundary_codes:)
      @latitude = Float(latitude)
      @longitude = Float(longitude)
      @boundary_codes = Array(boundary_codes).map(&:to_s)
    end

    def evaluate
      return Result.new(allowed: false, reason: "coordinates_out_of_range", boundary_codes: []) unless @latitude.between?(-90.0, 90.0) && @longitude.between?(-180.0, 180.0)
      return Result.new(allowed: false, reason: "no_boundaries_configured", boundary_codes: []) if @boundary_codes.empty?

      point = "ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography"
      matches = Spree::GeographicBoundary
        .where(code: @boundary_codes)
        .where("ST_Covers(boundary, #{point})", @longitude, @latitude)
        .pluck(:code)

      Result.new(
        allowed: matches.any?,
        reason: matches.any? ? "point_inside_boundary" : "point_outside_boundary",
        boundary_codes: matches
      )
    rescue ArgumentError, TypeError
      Result.new(allowed: false, reason: "invalid_coordinates", boundary_codes: [])
    end
  end
end
