require "rails_helper"

RSpec.describe Spree::Checkout::AllocationAuthorizationCommand do
  let(:allocation) { instance_double(Spree::PlanAllocation, id: 101, currency: "NGN", metadata: {}, policy: policy) }
  let(:policy) { { "geo_policy" => { "classification" => "lga", "country_codes" => ["NG"] } } }
  let(:geo_result) { OpenStruct.new(allowed: true, reason: "geo_policy_matched", evidence: { "hierarchy" => {} }) }
  let(:authorization) { OpenStruct.new(allowed: true, reason: "reserved", allocation: allocation, ledger_entry: :entry) }

  let(:context) do
    {
      user_id: "user-1", vendor_id: "vendor-1", store_id: "store-1", product_id: "product-1",
      latitude: 9.0765, longitude: 7.3986, country_code: "NG", coordinate_source: "device"
    }
  end

  before do
    allow(Spree::NestedGeographyResolver).to receive(:call).and_return(geo_result)
    allow(Spree::GeoPolicyEngine).to receive(:evaluate).and_return(geo_result)
    allow(Spree::GeoAuditCommand).to receive(:record!)
    allow(Spree::AllocationAuthorization).to receive(:reserve!).and_return(authorization)
  end

  it "requires coordinates when a geo policy exists" do
    context.delete(:latitude)
    context.delete(:longitude)
    result = described_class.call(allocation:, amount_minor: 1000, idempotency_key: "k-1", correlation_id: "c-1", context:)
    expect(result.allowed).to be(false)
    expect(result.reason).to eq("geo_coordinates_required")
    expect(Spree::AllocationAuthorization).not_to have_received(:reserve!)
  end

  it "rejects an inconsistent nested hierarchy" do
    allow(Spree::NestedGeographyResolver).to receive(:call).and_return(
      OpenStruct.new(allowed: false, reason: "nested_geography_inconsistent", matches: { "state" => [] })
    )
    result = described_class.call(allocation:, amount_minor: 1000, idempotency_key: "k-2", correlation_id: "c-2", context:)
    expect(result.allowed).to be(false)
    expect(result.reason).to eq("nested_geography_inconsistent")
    expect(Spree::AllocationAuthorization).not_to have_received(:reserve!)
  end

  it "rejects when the spatial policy does not match" do
    allow(Spree::GeoPolicyEngine).to receive(:evaluate).and_return(
      OpenStruct.new(allowed: false, reason: "lga_not_permitted", evidence: {})
    )
    result = described_class.call(allocation:, amount_minor: 1000, idempotency_key: "k-3", correlation_id: "c-3", context:)
    expect(result.allowed).to be(false)
    expect(result.reason).to eq("lga_not_permitted")
    expect(Spree::GeoAuditCommand).to have_received(:record!).with(hash_including(resolution_status: "REJECTED"))
    expect(Spree::AllocationAuthorization).not_to have_received(:reserve!)
  end

  it "audits and reserves after a successful spatial decision" do
    result = described_class.call(allocation:, amount_minor: 1000, idempotency_key: "k-4", correlation_id: "c-4", context:)
    expect(result.allowed).to be(true)
    expect(Spree::GeoAuditCommand).to have_received(:record!).with(hash_including(resolution_status: "RESOLVED"))
    expect(Spree::AllocationAuthorization).to have_received(:reserve!).with(hash_including(amount_minor: 1000, idempotency_key: "k-4", correlation_id: "c-4"))
  end
end
