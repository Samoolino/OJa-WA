require 'spec_helper'

RSpec.describe Spree::AllocationLedgerCommand, type: :service do
  let(:allocation) do
    create(
      :plan_allocation,
      status: :active,
      funded_minor: 100_000,
      reserved_minor: 40_000,
      consumed_minor: 0,
      released_minor: 0,
      reversed_minor: 0,
      currency: "NGN"
    )
  end

  it 'consumes a reservation atomically' do
    result = described_class.call(
      allocation:,
      entry_type: "consume",
      amount_minor: 40_000,
      operation_id: "op-consume-1",
      idempotency_key: "consume-1",
      correlation_id: "corr-1"
    )

    expect(result.applied).to be(true)
    allocation.reload
    expect(allocation.reserved_minor).to eq(0)
    expect(allocation.consumed_minor).to eq(40_000)
    expect(allocation.available_minor).to eq(60_000)
  end

  it 'releases a reservation atomically' do
    result = described_class.call(
      allocation:,
      entry_type: "release",
      amount_minor: 10_000,
      operation_id: "op-release-1",
      idempotency_key: "release-1",
      correlation_id: "corr-1"
    )

    expect(result.applied).to be(true)
    allocation.reload
    expect(allocation.reserved_minor).to eq(30_000)
    expect(allocation.released_minor).to eq(10_000)
    expect(allocation.available_minor).to eq(70_000)
  end

  it 'rejects a reverse larger than consumed balance' do
    expect {
      described_class.call(
        allocation:,
        entry_type: "reverse",
        amount_minor: 1,
        operation_id: "op-reverse-1",
        idempotency_key: "reverse-1",
        correlation_id: "corr-1"
      )
    }.to raise_error(ArgumentError, "consumed balance is insufficient")
  end
end
