require 'spec_helper'

RSpec.describe 'Spree allocation financial integrity' do
  let(:allocation) do
    Spree::PlanAllocation.create!(
      allocation_code: SecureRandom.alphanumeric(8).upcase,
      status: :active,
      currency: 'USD',
      funded_cents: 0
    )
  end

  it 'records verified funding exactly once on replay' do
    first = Spree::Funding::Issue.new.call(
      plan_allocation: allocation,
      amount_cents: 10_000,
      currency: 'USD',
      source_type: 'institutional',
      source_reference: 'fund-001',
      provider: 'sandbox',
      status: 'verified',
      idempotency_key: 'funding-001',
      correlation_id: 'corr-001',
      evidence: { test: true }
    )
    second = Spree::Funding::Issue.new.call(
      plan_allocation: allocation,
      amount_cents: 10_000,
      currency: 'USD',
      source_type: 'institutional',
      source_reference: 'fund-001',
      provider: 'sandbox',
      status: 'verified',
      idempotency_key: 'funding-001',
      correlation_id: 'corr-001',
      evidence: { test: true }
    )

    expect(first).to be_success
    expect(second).to be_success
    expect(second.replay).to eq(true)
    expect(allocation.reload.funded_cents).to eq(10_000)
    expect(allocation.ledger_entries.where(entry_type: 'fund').count).to eq(1)
  end

  it 'never allows consume to exceed reserved balance' do
    allocation.update!(funded_cents: 10_000, reserved_cents: 2_500)

    result = Spree::Allocation::LedgerOperation.new.call(
      plan_allocation: allocation,
      amount_cents: 2_501,
      currency: 'USD',
      operation: 'consume',
      idempotency_key: 'consume-too-large',
      correlation_id: 'corr-002',
      source_type: 'order',
      source_reference: 'order-001'
    )

    expect(result).not_to be_success
    expect(allocation.reload.reserved_cents).to eq(2_500)
    expect(allocation.consumed_cents).to eq(0)
  end

  it 'maintains the available balance invariant across consume and reverse' do
    allocation.update!(funded_cents: 10_000, reserved_cents: 3_000)

    consume = Spree::Allocation::LedgerOperation.new.call(
      plan_allocation: allocation,
      amount_cents: 3_000,
      currency: 'USD',
      operation: 'consume',
      idempotency_key: 'consume-001',
      correlation_id: 'corr-003',
      source_type: 'order',
      source_reference: 'order-002'
    )
    expect(consume).to be_success
    expect(allocation.reload.available_cents).to eq(7_000)

    reverse = Spree::Allocation::LedgerOperation.new.call(
      plan_allocation: allocation,
      amount_cents: 3_000,
      currency: 'USD',
      operation: 'reverse',
      idempotency_key: 'reverse-001',
      correlation_id: 'corr-004',
      source_type: 'refund',
      source_reference: 'refund-001'
    )
    expect(reverse).to be_success
    expect(allocation.reload.available_cents).to eq(10_000)
  end

  it 'atomically reserves against the available balance and replays idempotently' do
    allocation.update!(funded_cents: 5_000, currency: 'USD')
    user = instance_double('User', id: 42)
    allocation.update!(user_id: 42)

    first = Spree::Allocation::Reserve.new.call(
      plan_allocation: allocation,
      user: user,
      amount_cents: 3_000,
      currency: 'USD',
      idempotency_key: 'reserve-001',
      correlation_id: 'corr-005',
      source_reference: 'order-003'
    )
    second = Spree::Allocation::Reserve.new.call(
      plan_allocation: allocation,
      user: user,
      amount_cents: 3_000,
      currency: 'USD',
      idempotency_key: 'reserve-001',
      correlation_id: 'corr-005',
      source_reference: 'order-003'
    )

    expect(first).to be_success
    expect(second).to be_success
    expect(second.replay).to eq(true)
    expect(allocation.reload.reserved_cents).to eq(3_000)
    expect(allocation.ledger_entries.where(entry_type: 'reserve').count).to eq(1)
  end

end
