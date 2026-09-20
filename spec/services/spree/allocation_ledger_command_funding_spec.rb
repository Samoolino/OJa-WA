require "rails_helper"

RSpec.describe Spree::AllocationLedgerCommand do
  let(:allocation) do
    Spree::PlanAllocation.create!(
      status: :active,
      funded_minor: 0,
      reserved_minor: 0,
      consumed_minor: 0,
      released_minor: 0,
      reversed_minor: 0,
      currency: "USD"
    )
  end

  it "applies an idempotent fund entry without touching reserved or consumed balances" do
    result = described_class.call(
      allocation: allocation,
      entry_type: "fund",
      amount_minor: 1_000,
      operation_id: "fund:#{allocation.id}",
      idempotency_key: "fund:#{allocation.id}",
      correlation_id: "corr:fund"
    )

    expect(result.applied).to be(true)
    allocation.reload
    expect(allocation.funded_minor).to eq(1_000)
    expect(allocation.reserved_minor).to eq(0)
    expect(allocation.consumed_minor).to eq(0)
    expect(allocation.available_minor).to eq(1_000)

    replay = described_class.call(
      allocation: allocation,
      entry_type: "fund",
      amount_minor: 1_000,
      operation_id: "fund:#{allocation.id}",
      idempotency_key: "fund:#{allocation.id}",
      correlation_id: "corr:fund"
    )

    expect(replay.reason).to eq("idempotent_replay")
    expect(allocation.reload.funded_minor).to eq(1_000)
    expect(allocation.allocation_ledger_entries.count).to eq(1)
  end
end
