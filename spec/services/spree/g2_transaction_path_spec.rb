require 'spec_helper'

RSpec.describe 'OJa-WA G2 transaction path' do
  let(:user) { instance_double('User', id: 42) }

  it 'certifies verified funding through reserve, capture, fulfillment, settlement, and refund' do
    allocation = Spree::PlanAllocation.create!(
      allocation_code: 'G2-E2E-001',
      status: :active,
      currency: 'USD',
      funded_cents: 0,
      reserved_cents: 0,
      consumed_cents: 0,
      released_cents: 0,
      reversed_cents: 0
    )

    funding = Spree::Funding::Issue.new.call(
      plan_allocation: allocation,
      amount_cents: 10_000,
      currency: 'USD',
      source_type: 'sponsor',
      source_reference: 'G2-SPONSOR-001',
      provider: 'sandbox',
      status: 'verified',
      idempotency_key: 'g2-funding-001',
      correlation_id: 'g2-corr-funding-001',
      evidence: { verification: 'sandbox-verified' }
    )
    expect(funding).to be_success
    expect(allocation.reload.funded_cents).to eq(10_000)

    funding_replay = Spree::Funding::Issue.new.call(
      plan_allocation: allocation,
      amount_cents: 10_000,
      currency: 'USD',
      source_type: 'sponsor',
      source_reference: 'G2-SPONSOR-001',
      provider: 'sandbox',
      status: 'verified',
      idempotency_key: 'g2-funding-001',
      correlation_id: 'g2-corr-funding-replay',
      evidence: { verification: 'sandbox-verified' }
    )
    expect(funding_replay).to be_success
    expect(funding_replay.replay).to be(true)
    expect(allocation.reload.funded_cents).to eq(10_000)

    basket = [
      { sku: 'G2-SKU-1', quantity: 2, unit_price_cents: 2_000 },
      { sku: 'G2-SKU-2', quantity: 1, unit_price_cents: 2_000 }
    ]

    split_result = Spree::Checkout::CreateOrderSplit.new.call(
      order_reference: 'G2-ORDER-001',
      cart_reference: 'G2-CART-001',
      vendor_id: 7001,
      vendor_store_id: 8001,
      currency: 'USD',
      line_items: basket,
      correlation_id: 'g2-corr-order-001'
    )
    expect(split_result).to be_success

    reservation = Spree::Allocation::Reserve.new.call(
      plan_allocation: allocation,
      user: user,
      amount_cents: 6_000,
      currency: 'USD',
      idempotency_key: 'g2-reserve-001',
      correlation_id: 'g2-corr-reserve-001',
      source_reference: 'G2-ORDER-001'
    )
    expect(reservation).to be_success
    expect(allocation.reload.reserved_cents).to eq(6_000)

    capture = Spree::Payment::CaptureOrderSplit.new.call(
      order_id: 9001,
      split: split_result.split,
      allocation: allocation,
      user: user,
      amount_cents: 6_000,
      currency: 'USD',
      provider: 'sandbox',
      provider_event_id: 'g2-payment-event-001',
      payment_payload: { amount_cents: 6_000, currency: 'USD', order: 'G2-ORDER-001' },
      reserve_idempotency_key: 'g2-reserve-001',
      capture_idempotency_key: 'g2-capture-001',
      fulfillment_mode: 'delivery',
      fulfillment_idempotency_key: 'g2-fulfillment-001',
      settlement_idempotency_key: 'g2-settlement-001',
      platform_fee_cents: 500,
      line_items: basket,
      correlation_id: 'g2-corr-capture-001',
      vendor_account_ready: true
    )
    expect(capture).to be_success
    expect(capture.capture.reconciliation.status).to eq('MATCHED')
    expect(capture.split.status).to eq('CAPTURED')
    expect(capture.fulfillment.status).to eq('pending')
    expect(capture.settlement.status).to eq('blocked')
    expect(allocation.reload.consumed_cents).to eq(6_000)

    confirmed = Spree::Fulfillment::Transition.new.call(
      fulfillment: capture.fulfillment,
      to: 'confirmed',
      correlation_id: 'g2-corr-fulfillment-001'
    )
    expect(confirmed).to be_success
    expect(confirmed.fulfillment.status).to eq('confirmed')

    transfer = Spree::Settlement::RequestTransfer.new.call(
      settlement: capture.settlement,
      payment_captured: true,
      vendor_account_ready: true,
      fulfillment_required: true,
      fulfillment_confirmed: true,
      reconciliation_status: 'MATCHED',
      transfer_idempotency_key: 'g2-transfer-001',
      correlation_id: 'g2-corr-transfer-001'
    )
    expect(transfer).to be_success
    expect(transfer.settlement.status).to eq('requested')

    refund = Spree::Payment::RefundAllocation.new.call(
      plan_allocation: allocation,
      user: user,
      amount_cents: 6_000,
      currency: 'USD',
      refund_idempotency_key: 'g2-refund-001',
      correlation_id: 'g2-corr-refund-001',
      source_reference: 'G2-ORDER-001'
    )
    expect(refund).to be_success

    final = allocation.reload
    expect(final.consumed_cents).to eq(0)
    expect(final.reversed_cents).to eq(6_000)
    expect(final.available_cents).to eq(10_000)
  end

  it 'rejects provider currency mismatch without consuming the reservation' do
    allocation = Spree::PlanAllocation.create!(
      allocation_code: 'G2-E2E-002',
      status: :active,
      currency: 'USD',
      funded_cents: 10_000,
      reserved_cents: 6_000
    )
    Spree::AllocationLedgerEntry.create!(
      plan_allocation: allocation,
      entry_type: 'reserve',
      amount_cents: 6_000,
      currency: 'USD',
      idempotency_key: 'g2-reserve-002',
      correlation_id: 'g2-corr-reserve-002',
      source_type: 'order',
      source_reference: 'G2-ORDER-002',
      occurred_at: Time.current
    )

    result = Spree::Payment::CaptureAllocation.new.call(
      plan_allocation: allocation,
      user: user,
      amount_cents: 6_000,
      currency: 'USD',
      provider: 'sandbox',
      provider_event_id: 'g2-payment-event-002',
      payment_payload: { amount_cents: 6_000, currency: 'EUR' },
      reserve_idempotency_key: 'g2-reserve-002',
      capture_idempotency_key: 'g2-capture-002',
      correlation_id: 'g2-corr-capture-002'
    )

    expect(result).to be_success
    expect(result.reconciliation.status).to eq('CURRENCY_MISMATCH')
    expect(allocation.reload.consumed_cents).to eq(0)
    expect(allocation.reload.reserved_cents).to eq(6_000)
  end
end
