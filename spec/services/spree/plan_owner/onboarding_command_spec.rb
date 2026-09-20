require 'spec_helper'

RSpec.describe Spree::PlanOwner::OnboardingCommand do
  let(:plan_owner) { create(:user) }

  def run(command, plan: nil, attributes: {}, key: SecureRandom.uuid)
    described_class.new(
      plan_owner: plan_owner,
      plan: plan,
      command: command,
      attributes: attributes,
      idempotency_key: key,
      correlation_id: SecureRandom.uuid,
      request_id: SecureRandom.uuid
    ).call
  end

  it 'creates a draft and replays the same idempotent command' do
    key = SecureRandom.uuid
    attributes = {
      name: 'Community Food Plan',
      objective: 'Restricted institutional food support',
      currency: 'NGN',
      plan_type: 'recurring',
      funding_target_minor: 1_000_000
    }

    first = run('create', attributes: attributes, key: key)
    second = run('create', attributes: attributes, key: key)

    expect(first.payload[:status]).to eq('draft')
    expect(second.replayed?).to be(true)
    expect(second.payload[:plan_id]).to eq(first.payload[:plan_id])
    expect(Spree::SubscriptionPlan.where(plan_owner: plan_owner).count).to eq(1)
  end

  it 'does not activate before allocation and policy are configured' do
    created = run('create', attributes: {
      name: 'Restricted Basket',
      objective: 'Food support',
      currency: 'NGN',
      funding_target_minor: 500_000
    })

    plan = Spree::SubscriptionPlan.find(created.payload[:plan_id])

    expect {
      run('activate', plan: plan, key: SecureRandom.uuid)
    }.to raise_error(ArgumentError, 'ACTIVATION_BLOCKED')
  end

  it 'becomes review ready after allocation and policy configuration' do
    created = run('create', attributes: {
      name: 'School Support',
      objective: 'Institutional beneficiary support',
      currency: 'NGN',
      funding_target_minor: 500_000
    })

    plan = Spree::SubscriptionPlan.find(created.payload[:plan_id])
    run('allocation', plan: plan, attributes: {
      allocation: { access_method: 'qr', distribution_mode: 'fixed' }
    })
    result = run('policy', plan: plan, attributes: {
      policy: { purpose_category: 'food', geography: 'approved_store_zone' }
    })

    expect(result.payload[:onboarding_state]).to eq('REVIEW_READY')
    expect(result.payload[:missing_requirements]).to eq([])
  end
end
