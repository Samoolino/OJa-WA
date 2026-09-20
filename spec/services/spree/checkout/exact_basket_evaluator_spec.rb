require 'spec_helper'

RSpec.describe Spree::Checkout::ExactBasketEvaluator, type: :service do
  let(:vendor) { create(:vendor) }
  let(:store) { create(:vendor_store, vendor: vendor, state: :active) }
  let(:allocation) do
    create(
      :plan_allocation,
      vendor: vendor,
      vendor_store: store,
      status: :active,
      funded_minor: 100_000,
      reserved_minor: 0,
      consumed_minor: 0,
      released_minor: 0,
      reversed_minor: 0,
      currency: "NGN",
      policy: { "product_ids" => ["42"] }
    )
  end

  it 'accepts a basket whose products and store geography satisfy policy' do
    result = described_class.call(
      allocation: allocation,
      line_items: [{ product_id: 42, amount_minor: 25_000 }],
      context: { store:, product_id: 42, vendor_id: vendor.id, store_id: store.id }
    )

    expect(result).to be_allowed
    expect(result.amount_minor).to eq(25_000)
  end

  it 'rejects a product outside the allocation policy' do
    result = described_class.call(
      allocation: allocation,
      line_items: [{ product_id: 99, amount_minor: 25_000 }],
      context: { store:, product_id: 99, vendor_id: vendor.id, store_id: store.id }
    )

    expect(result).not_to be_allowed
    expect(result.reason).to eq("product_mismatch")
  end
end
