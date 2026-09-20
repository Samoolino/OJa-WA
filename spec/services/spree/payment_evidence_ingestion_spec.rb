require 'spec_helper'

RSpec.describe Spree::PaymentEvidenceIngestion, type: :service do
  let(:attrs) do
    {
      provider: "stripe",
      provider_event_id: "evt_test_123",
      event_type: "payment_intent.succeeded",
      status: "CAPTURED",
      correlation_id: SecureRandom.uuid,
      payment_reference: "pi_test_123",
      currency: "NGN",
      amount_minor: 150_000,
      payload: { "test" => true }
    }
  end

  it 'deduplicates provider events' do
    first = described_class.call(**attrs)
    second = described_class.call(**attrs)

    expect(second.id).to eq(first.id)
    expect(Spree::PaymentEvidenceEvent.count).to eq(1)
  end

  it 'rejects negative monetary evidence' do
    expect {
      described_class.call(**attrs.merge(amount_minor: -1))
    }.to raise_error(ArgumentError, "amount_minor must not be negative")
  end
end
