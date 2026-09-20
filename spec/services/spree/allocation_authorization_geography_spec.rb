require "rails_helper"

RSpec.describe Spree::AllocationAuthorization do
  def authorization(context = {})
    described_class.new(
      allocation: instance_double(Spree::PlanAllocation),
      amount_minor: 1_000,
      operation_id: "op-geo-1",
      idempotency_key: "idem-geo-1",
      correlation_id: "corr-geo-1",
      context:
    )
  end

  it "rejects direct authorization when a geographic policy has no verified evidence" do
    allocation = instance_double(
      Spree::PlanAllocation,
      active?: true,
      expires_at: nil,
      policy: { "geo_policy" => { "country_code" => "NG" } },
      metadata: {},
      available_minor: 10_000
    )

    expect(authorization.send(:policy_failure, allocation))
      .to eq("geography_evidence_required")
  end

  it "accepts the geographic gate only with an authorization flag and evidence" do
    allocation = instance_double(
      Spree::PlanAllocation,
      active?: true,
      expires_at: nil,
      policy: { "geo_policy" => { "country_code" => "NG" } },
      metadata: {},
      available_minor: 10_000
    )

    context = {
      geo_authorized: true,
      geo_evidence: { "hierarchy" => { "country" => [{ "code" => "NG" }] } }
    }

    expect(authorization(context).send(:policy_failure, allocation)).to be_nil
  end
end
