module Spree
  class GeoSpatialMatcher
    Result = Struct.new(:allowed, :reason, :store_ids, :region_codes, keyword_init: true)

    def self.match(latitude:, longitude:, geo_policy:)
      new(latitude:, longitude:, geo_policy:).match
    end

    def initialize(latitude:, longitude:, geo_policy:)
      @latitude = Float(latitude)
      @longitude = Float(longitude)
      @policy = geo_policy || {}
    end

    def match
      region_codes = permitted_regions
      stores = Spree::VendorStore.where(status: "ACTIVE")

      if region_codes.any?
        stores = stores.joins(:geo_region).where(spree_geo_regions: { code: region_codes })
      end

      point = "SRID=4326;POINT(#{@longitude} #{@latitude})"
      stores = stores.where("ST_DWithin(location, ST_GeogFromText(?), ?)", point, permitted_radius_meters)

      if @policy["boundary_required"]
        stores = stores.where(
          "EXISTS (SELECT 1 FROM spree_geo_regions r WHERE r.id = spree_vendor_stores.geo_region_id AND ST_Contains(r.boundary::geometry, ST_GeomFromText(?, 4326)))",
          "POINT(#{@longitude} #{@latitude})"
        )
      end

      ids = stores.pluck(:id)
      return Result.new(allowed: false, reason: "no_verified_store_in_boundary", store_ids: [], region_codes:) if ids.empty?

      Result.new(allowed: true, reason: "spatial_match", store_ids: ids, region_codes:)
    rescue ArgumentError
      Result.new(allowed: false, reason: "invalid_coordinates", store_ids: [], region_codes: [])
    end

    private

    def permitted_regions
      Array(@policy["region_codes"] || @policy[:region_codes]).map(&:to_s)
    end

    def permitted_radius_meters
      value = @policy["radius_meters"] || @policy[:radius_meters] || 100
      [[Float(value), 1].max, 10_000].min
    end
  end
end
