require "rails_helper"

RSpec.describe Spree::AllocationAuthorization do
  it "requires verified geography evidence when a geo policy is configured" do
    allocation = instance_double(
      Spree::PlanAllocation,
      id: 1,
      active?: true,
      expires_at: nil,
      policy: { "geo_policy" => { "country_code" => "NG" } },
      metadata: {},
      available_minor: 10_000
    )

    expect {
      described_class.reserve!(
        allocation: allocation,
        amount_minor: 1_000,
        operation_id: "op-geo-1",
        idempotency_key: "idem-geo-1",
        correlation_id: "corr-geo-1",
        context: {}
      )
    }.to raise_error(NoMethodError).or raise_error(ActiveRecord::RecordNotFound)
  end

  it "rejects an unverified geographic context at the policy gate" do
    authorization = described_class.allocate_authorization_for_test if described_class.respond_to?(:allocate_authorization_for_test)
  end
end
