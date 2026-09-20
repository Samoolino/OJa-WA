require 'spec_helper'

RSpec.describe 'Spree order lifecycle integrity' do
  it 'validates an order split basket before capture' do
    result = Spree::Checkout::ExactBasket.new.call(
      line_items: [
        { sku: 'SKU-1', quantity: 2, unit_price_cents: 2_500 },
        { sku: 'SKU-2', quantity: 1, unit_price_cents: 5_000 }
      ],
      expected_amount_cents: 10_000,
      currency: 'USD'
    )

    expect(result).to be_success
    expect(result.total_cents).to eq(10_000)
  end

  it 'rejects a basket whose calculated amount differs from the authorization amount' do
    result = Spree::Checkout::ExactBasket.new.call(
      line_items: [{ sku: 'SKU-1', quantity: 1, unit_price_cents: 9_999 }],
      expected_amount_cents: 10_000,
      currency: 'USD'
    )

    expect(result).not_to be_success
    expect(result.errors).to include('basket amount mismatch')
  end

  it 'allows fulfillment confirmation only through a valid transition' do
    fulfillment = Spree::OrderFulfillment.create!(
      order_id: 1001, vendor_reference: 'vendor-1',
      fulfillment_mode: 'delivery', status: 'pending',
      idempotency_key: 'fulfill-lifecycle-1', correlation_id: 'corr-life-1'
    )

    result = Spree::Fulfillment::Transition.new.call(
      fulfillment: fulfillment, to: 'confirmed', correlation_id: 'corr-life-2'
    )

    expect(result).to be_success
    expect(result.fulfillment.status).to eq('confirmed')
    expect(result.fulfillment.confirmed_at).to be_present
  end

  it 'blocks settlement unless all institutional gates are satisfied' do
    result = Spree::Settlement::Eligibility.new.call(
      payment_captured: true,
      vendor_account_ready: true,
      fulfillment_required: true,
      fulfillment_confirmed: false,
      reconciliation_status: 'MATCHED'
    )

    expect(result).not_to be_success
    expect(result.errors).to include('fulfillment not confirmed')
  end

  it 'releases a reservation through the same immutable ledger boundary' do
    allocation = Spree::PlanAllocation.create!(
      allocation_code: SecureRandom.alphanumeric(8).upcase,
      status: :active,
      currency: 'USD',
      funded_cents: 10_000,
      reserved_cents: 3_000
    )

    reserve = Spree::Allocation::LedgerOperation.new.call(
      plan_allocation: allocation, amount_cents: 3_000, currency: 'USD',
      operation: 'reserve', idempotency_key: 'reserve-life-1',
      correlation_id: 'corr-life-3', source_type: 'order', source_reference: 'order-life-1'
    )
    expect(reserve).to be_success

    result = Spree::Allocation::Release.new.call(
      plan_allocation: allocation, amount_cents: 3_000, currency: 'USD',
      idempotency_key: 'release-life-1', correlation_id: 'corr-life-4',
      source_reference: 'order-life-1'
    )

    expect(result).to be_success
    expect(allocation.reload.reserved_cents).to eq(3_000)
    expect(allocation.released_cents).to eq(3_000)
  end
end
