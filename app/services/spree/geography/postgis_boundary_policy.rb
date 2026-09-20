module Spree
  module Geography
    class PostgisBoundaryPolicy
      Result = Struct.new(:allowed, :reason, :boundary, keyword_init: true)

      def self.evaluate(latitude:, longitude:, level:, codes:)
        new(latitude:, longitude:, level:, codes:).evaluate
      end

      def initialize(latitude:, longitude:, level:, codes:)
        @latitude = Float(latitude)
        @longitude = Float(longitude)
        @level = level.to_s
        @codes = Array(codes).map(&:to_s)
      end

      def evaluate
        return Result.new(allowed: false, reason: "invalid_coordinate") unless valid_coordinate?
        return Result.new(allowed: false, reason: "invalid_level") unless %w[country state region lga district zone store].include?(@level)
        return Result.new(allowed: false, reason: "no_boundary_codes") if @codes.empty?

        point = "SRID=4326;POINT(#{@longitude} #{@latitude})"
        boundary = Spree::GeographicPolicyBoundary
          .where(level: @level, code: @codes)
          .where("ST_Contains(boundary, ST_GeogFromText(?))", point)
          .first

        if boundary
          Result.new(allowed: true, reason: "point_inside_boundary", boundary:)
        else
          Result.new(allowed: false, reason: "point_outside_boundary")
        end
      end

      private

      def valid_coordinate?
        @latitude.between?(-90.0, 90.0) && @longitude.between?(-180.0, 180.0)
      end
    end
  end
end
