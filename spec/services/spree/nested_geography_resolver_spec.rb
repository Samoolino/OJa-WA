require "rails_helper"

RSpec.describe Spree::NestedGeographyResolver do
  it "rejects invalid coordinates" do
    result = described_class.call(latitude: 91, longitude: 3)
    expect(result.consistent).to be(false)
    expect(result.reason).to eq("invalid_coordinates")
  end

  it "rejects ambiguous overlapping boundaries at the same level" do
    rows = [
      ["NG", "Nigeria", "country", nil, "NG"],
      ["LA", "Lagos", "state", "NG", "NG"],
      ["LA-1", "Lagos One", "zone", "LA", "NG"],
      ["LA-2", "Lagos Two", "zone", "LA", "NG"]
    ]
    relation = double(order: double(pluck: rows))
    allow(Spree::GeographicBoundary).to receive(:where).and_return(relation)

    result = described_class.call(latitude: 6.5, longitude: 3.4)
    expect(result.consistent).to be(false)
    expect(result.reason).to eq("nested_geography_inconsistent")
  end

  it "reports an empty boundary result as unresolved" do
    allow(Spree::GeographicBoundary).to receive(:where).and_return(double(order: double(pluck: [])))
    result = described_class.call(latitude: 9.0, longitude: 7.0)
    expect(result.consistent).to be(false)
    expect(result.reason).to eq("nested_geography_inconsistent")
  end
end
