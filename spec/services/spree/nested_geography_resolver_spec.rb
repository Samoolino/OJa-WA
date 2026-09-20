require "rails_helper"

RSpec.describe Spree::NestedGeographyResolver do
  it "rejects invalid coordinates" do
    result = described_class.call(latitude: 91, longitude: 3)
    expect(result.consistent).to be(false)
    expect(result.reason).to eq("invalid_coordinates")
  end

  it "reports an empty boundary result as unresolved" do
    allow(Spree::GeographicBoundary).to receive(:where).and_return(double(order: double(pluck: [])))
    result = described_class.call(latitude: 9.0, longitude: 7.0)
    expect(result.consistent).to be(false)
    expect(result.reason).to eq("nested_geography_inconsistent")
  end
end
