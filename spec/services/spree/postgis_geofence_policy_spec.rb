require "rails_helper"

RSpec.describe Spree::PostgisGeofencePolicy do
  def polygon_wkt
    "POLYGON((-1 -1, 1 -1, 1 1, -1 1, -1 -1))"
  end

  def geography_from_wkt(wkt)
    RGeo::Geographic.spherical_factory(srid: 4326).parse_wkt(wkt)
  end

  before do
    Spree::GeographicBoundary.create!(
      code: "TEST-ZONE",
      name: "Test Zone",
      level: "zone",
      country_code: "NG",
      boundary: geography_from_wkt(polygon_wkt)
    )
  end

  it "allows a point inside a configured boundary" do
    result = described_class.evaluate(
      latitude: 0,
      longitude: 0,
      boundary_codes: ["TEST-ZONE"]
    )

    expect(result.allowed).to be(true)
    expect(result.reason).to eq("point_inside_boundary")
    expect(result.boundary_codes).to eq(["TEST-ZONE"])
  end

  it "allows a point on the boundary edge" do
    result = described_class.evaluate(
      latitude: 1,
      longitude: 0,
      boundary_codes: ["TEST-ZONE"]
    )

    expect(result.allowed).to be(true)
    expect(result.reason).to eq("point_inside_boundary")
  end

  it "rejects a point outside the configured boundary" do
    result = described_class.evaluate(
      latitude: 2,
      longitude: 0,
      boundary_codes: ["TEST-ZONE"]
    )

    expect(result.allowed).to be(false)
    expect(result.reason).to eq("point_outside_boundary")
    expect(result.boundary_codes).to eq([])
  end

  it "rejects an empty boundary allow-list" do
    result = described_class.evaluate(
      latitude: 0,
      longitude: 0,
      boundary_codes: []
    )

    expect(result.allowed).to be(false)
    expect(result.reason).to eq("no_boundaries_configured")
  end
end
