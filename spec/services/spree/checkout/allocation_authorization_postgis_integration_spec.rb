require "rails_helper"

RSpec.describe Spree::Checkout::AllocationAuthorizationCommand do
  def geography_from_wkt(wkt)
    RGeo::Geographic.spherical_factory(srid: 4326).parse_wkt(wkt)
  end

  def test_boundary(code:, level:, parent_code: nil)
    Spree::GeographicBoundary.create!(
      code: code,
      name: code,
      level: level,
      country_code: "NG",
      parent_code: parent_code,
      boundary: geography_from_wkt("POLYGON((-1 -1, 1 -1, 1 1, -1 1, -1 -1))")
    )
  end

  def allocation
    @allocation ||= Spree::PlanAllocation.create!(
      status: :active,
      funded_minor: 1_000,
      reserved_minor: 0,
      consumed_minor: 0,
      released_minor: 0,
      reversed_minor: 0,
      currency: "USD",
      policy: {
        "geo_policy" => {
          "classification" => "lga",
          "country_codes" => ["NG"],
          "lga_codes" => ["LGA-TEST"]
        }
      },
      metadata: {}
    )
  end

  let(:context) do
    {
      user_id: "beneficiary-1",
      vendor_id: "vendor-1",
      store_id: "store-1",
      product_id: "product-1",
      latitude: 0,
      longitude: 0,
      country_code: "NG",
      coordinate_source: "test-fixture"
    }
  end

  before do
    test_boundary(code: "NG-TEST", level: "country")
    test_boundary(code: "NG-STATE", level: "state", parent_code: "NG-TEST")
    test_boundary(code: "LGA-TEST", level: "lga", parent_code: "NG-STATE")
    test_boundary(code: "ZONE-TEST", level: "zone", parent_code: "LGA-TEST")
  end

  it "executes the full spatial authorization path and commits audit plus reservation atomically" do
    result = described_class.call(
      allocation: allocation,
      amount_minor: 250,
      idempotency_key: "checkout-geo-001",
      correlation_id: "corr-geo-001",
      context: context
    )

    expect(result.allowed).to be(true)
    expect(result.reason).to eq("reserved")

    allocation.reload
    expect(allocation.reserved_minor).to eq(250)
    expect(allocation.available_minor).to eq(750)

    ledger = allocation.allocation_ledger_entries.find_by!(idempotency_key: "checkout-geo-001")
    expect(ledger.entry_type).to eq("reserve")
    expect(ledger.amount_minor).to eq(250)
    expect(ledger.correlation_id).to eq("corr-geo-001")

    audit = Spree::GeoAuditRecord.find_by!(operation_id: "geo-audit:allocation:#{allocation.id}:checkout-geo-001")
    expect(audit.resolution_status).to eq("RESOLVED")
    expect(audit.resolved_hierarchy.dig("country", 0, "code")).to eq("NG-TEST")
    expect(audit.resolved_hierarchy.dig("state", 0, "code")).to eq("NG-STATE")
    expect(audit.resolved_hierarchy.dig("lga", 0, "code")).to eq("LGA-TEST")
    expect(audit.policy_result["allowed"]).to be(true)
  end

  it "fails closed before reservation when the spatial policy does not match" do
    allocation.update!(
      policy: {
        "geo_policy" => {
          "classification" => "lga",
          "country_codes" => ["NG"],
          "lga_codes" => ["LGA-NOT-ALLOWED"]
        }
      }
    )

    result = described_class.call(
      allocation: allocation,
      amount_minor: 250,
      idempotency_key: "checkout-geo-002",
      correlation_id: "corr-geo-002",
      context: context
    )

    expect(result.allowed).to be(false)
    expect(result.reason).to eq("lga_not_permitted")

    allocation.reload
    expect(allocation.reserved_minor).to eq(0)
    expect(allocation.allocation_ledger_entries).to be_empty

    audit = Spree::GeoAuditRecord.find_by!(operation_id: "geo-audit:allocation:#{allocation.id}:checkout-geo-002")
    expect(audit.resolution_status).to eq("REJECTED")
    expect(audit.policy_result["reason"]).to eq("lga_not_permitted")
  end

  it "rolls back the geo audit when the reservation ledger write fails" do
    allow_any_instance_of(Spree::AllocationLedgerEntry).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(Spree::AllocationLedgerEntry.new))

    expect {
      described_class.call(
        allocation: allocation,
        amount_minor: 250,
        idempotency_key: "checkout-geo-003",
        correlation_id: "corr-geo-003",
        context: context
      )
    }.to raise_error(ActiveRecord::RecordInvalid)

    expect(
      Spree::GeoAuditRecord.where(operation_id: "geo-audit:allocation:#{allocation.id}:checkout-geo-003")
    ).to be_empty

    allocation.reload
    expect(allocation.reserved_minor).to eq(0)
  end
end
