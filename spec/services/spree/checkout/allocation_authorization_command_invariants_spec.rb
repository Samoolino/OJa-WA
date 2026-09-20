require "rails_helper"

RSpec.describe Spree::Checkout::AllocationAuthorizationCommand do
  let(:allocation) do
    instance_double(Spree::PlanAllocation, id: 42, currency: "NGN", metadata: {}, policy: {})
  end
  let(:context) do
    { user_id: "user-1", vendor_id: "vendor-1", store_id: "store-1", product_id: "product-1" }
  end

  before do
    allow(Spree::GeoAuditCommand).to receive(:record!)
  end

  it "does not authorize a non-positive amount" do
    expect {
      described_class.call(allocation:, amount_minor: 0, idempotency_key: "k", correlation_id: "c", context:)
    }.to raise_error(ArgumentError, /greater than zero/)
  end

  it "does not authorize when required request identity is missing" do
    context.delete(:vendor_id)
    expect {
      described_class.call(allocation:, amount_minor: 100, idempotency_key: "k", correlation_id: "c", context:)
    }.to raise_error(ArgumentError, /vendor_id is required/)
  end

  it "keeps the reservation operation key equal to the client idempotency key" do
    authorization = OpenStruct.new(allowed: true, reason: "reserved", allocation:, ledger_entry: :entry)
    allow(Spree::AllocationAuthorization).to receive(:reserve!).and_return(authorization)

    described_class.call(allocation:, amount_minor: 100, idempotency_key: "same-key", correlation_id: "corr", context:)

    expect(Spree::AllocationAuthorization).to have_received(:reserve!).with(
      hash_including(operation_id: "allocation-reservation:same-key", idempotency_key: "same-key", correlation_id: "corr")
    )
  end

  it "namespaces geo-audit operation ids by allocation" do
    geo_policy = { "classification" => "lga", "country_codes" => ["NG"] }
    allow(allocation).to receive(:policy).and_return("geo_policy" => geo_policy)
    hierarchy = OpenStruct.new(consistent: true, reason: "nested_geography_resolved", matches: { "country" => [{ "code" => "NG" }] })
    geo = OpenStruct.new(allowed: true, reason: "geo_policy_matched", evidence: {})
    allow(Spree::NestedGeographyResolver).to receive(:call).and_return(hierarchy)
    allow(Spree::GeoPolicyEngine).to receive(:evaluate).and_return(geo)
    allow(Spree::AllocationAuthorization).to receive(:reserve!).and_return(
      OpenStruct.new(allowed: true, reason: "reserved", allocation:, ledger_entry: :entry)
    )

    described_class.call(
      allocation:, amount_minor: 100, idempotency_key: "same-key", correlation_id: "corr",
      context: context.merge(latitude: 9.0, longitude: 7.0, country_code: "NG")
    )

    expect(Spree::GeoAuditCommand).to have_received(:record!).with(
      hash_including(operation_id: "geo-audit:allocation:42:same-key")
    )
  end
end
