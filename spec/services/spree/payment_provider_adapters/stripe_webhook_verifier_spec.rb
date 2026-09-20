require 'spec_helper'

RSpec.describe Spree::PaymentProviderAdapters::StripeWebhookVerifier do
  let(:payload) { { id: 'evt_test_001', type: 'payment_intent.succeeded', created: Time.current.to_i, data: { object: { id: 'pi_test_001', amount: 12000, currency: 'ngn', status: 'succeeded' } } } }
  let(:raw_payload) { JSON.generate(payload) }

  it 'blocks when the webhook secret is not configured' do
    stub_const('ENV', ENV.to_h.except('STRIPE_WEBHOOK_SECRET'))
    result = described_class.new(headers: { 'Stripe-Signature' => 'invalid' }, raw_payload:).verify
    expect(result.verified).to be(false)
    expect(result.reason).to eq('webhook_secret_not_configured')
  end

  it 'blocks a missing signature' do
    stub_const('ENV', ENV.to_h.merge('STRIPE_WEBHOOK_SECRET' => 'whsec_test'))
    result = described_class.new(headers: {}, raw_payload:).verify
    expect(result.verified).to be(false)
    expect(result.reason).to eq('signature_missing')
  end

  it 'blocks an invalid signature' do
    stub_const('ENV', ENV.to_h.merge('STRIPE_WEBHOOK_SECRET' => 'whsec_test'))
    result = described_class.new(headers: { 'Stripe-Signature' => 't=1,v1=invalid' }, raw_payload:).verify
    expect(result.verified).to be(false)
    expect(result.reason).to eq('signature_invalid')
  end
end
