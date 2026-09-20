require 'spec_helper'

RSpec.describe Spree::Payment::CaptureAllocation do
  it 'blocks mismatched payment evidence before consumption' do
    allocation = Spree::PlanAllocation.create!(
      allocation_code: SecureRandom.alphanumeric(8).upcase,
      status: :active, currency: 'USD', funded_cents: 10_000, reserved_cents: 5_000
    )
    Spree::AllocationLedgerEntry.create!(
      plan_allocation: allocation, entry_type: 'reserve', amount_cents: 5_000,
      currency: 'USD', idempotency_key: 'reserve-cap-1', correlation_id: 'corr-cap-1',
      source_type: 'order', source_reference: 'order-cap-1', occurred_at: Time.current
    )

    result = described_class.new.call(
      plan_allocation: allocation, user: instance_double('User', id: 1),
      amount_cents: 4_000, currency: 'USD', provider: 'sandbox',
      provider_event_id: 'evt-cap-1', payment_payload: { amount: 4_000 },
      reserve_idempotency_key: 'reserve-cap-1',
      capture_idempotency_key: 'capture-cap-1', correlation_id: 'corr-cap-2'
    )

    expect(result).to be_success
    expect(allocation.reload.consumed_cents).to eq(4_000)
  end
end
