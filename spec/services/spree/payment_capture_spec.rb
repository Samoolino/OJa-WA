require 'spec_helper'

RSpec.describe Spree::Payment::CaptureAllocation do
  def build_allocation
    allocation = Spree::PlanAllocation.create!(
      allocation_code: SecureRandom.alphanumeric(8).upcase,
      status: :active, currency: 'USD', funded_cents: 10_000, reserved_cents: 5_000
    )
    Spree::AllocationLedgerEntry.create!(
      plan_allocation: allocation, entry_type: 'reserve', amount_cents: 5_000,
      currency: 'USD', idempotency_key: 'reserve-cap-1', correlation_id: 'corr-cap-1',
      source_type: 'order', source_reference: 'order-cap-1', occurred_at: Time.current
    )
    allocation
  end

  def capture(allocation, event_id:, capture_key:, payload:)
    described_class.new.call(
      plan_allocation: allocation, user: instance_double('User', id: 1),
      amount_cents: 4_000, currency: 'USD', provider: 'sandbox',
      provider_event_id: event_id, payment_payload: payload,
      reserve_idempotency_key: 'reserve-cap-1',
      capture_idempotency_key: capture_key, correlation_id: "corr-#{capture_key}"
    )
  end

  it 'consumes only when provider evidence matches the expected capture' do
    allocation = build_allocation
    result = capture(allocation, event_id: 'evt-cap-1', capture_key: 'capture-cap-1',
                     payload: { amount_cents: 4_000, currency: 'USD' })
    expect(result).to be_success
    expect(result.reconciliation.status).to eq('MATCHED')
    expect(allocation.reload.consumed_cents).to eq(4_000)
  end

  it 'blocks a provider amount mismatch before consumption' do
    allocation = build_allocation
    result = capture(allocation, event_id: 'evt-cap-mismatch', capture_key: 'capture-cap-mismatch',
                     payload: { amount_cents: 3_900, currency: 'USD' })
    expect(result).to be_success
    expect(result.reconciliation.status).to eq('AMOUNT_MISMATCH')
    expect(result.reconciliation.matched).to be(false)
    expect(allocation.reload.consumed_cents).to eq(0)
    expect(allocation.reload.reserved_cents).to eq(5_000)
  end

  it 'treats the same provider event and payload as an idempotent replay' do
    allocation = build_allocation
    first = capture(allocation, event_id: 'evt-cap-replay', capture_key: 'capture-cap-replay',
                    payload: { amount_cents: 4_000, currency: 'USD' })
    second = capture(allocation, event_id: 'evt-cap-replay', capture_key: 'capture-cap-replay-2',
                     payload: { amount_cents: 4_000, currency: 'USD' })
    expect(first).to be_success
    expect(second).to be_success
    expect(second.evidence.id).to eq(first.evidence.id)
    expect(allocation.reload.consumed_cents).to eq(4_000)
  end

  it 'rejects the same provider event when its payload changes' do
    allocation = build_allocation
    first = capture(allocation, event_id: 'evt-cap-tamper', capture_key: 'capture-cap-tamper',
                    payload: { amount_cents: 4_000, currency: 'USD' })
    second = capture(allocation, event_id: 'evt-cap-tamper', capture_key: 'capture-cap-tamper-2',
                     payload: { amount_cents: 4_100, currency: 'USD' })
    expect(first).to be_success
    expect(second).not_to be_success
    expect(second.errors).to include('payment evidence mismatch')
    expect(allocation.reload.consumed_cents).to eq(4_000)
  end
end
