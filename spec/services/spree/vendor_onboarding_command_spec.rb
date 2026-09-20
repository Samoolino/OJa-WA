require 'spec_helper'

RSpec.describe Spree::VendorOnboardingCommand, type: :service do
  let(:vendor) { create(:vendor) }
  let(:actor) { create(:user) }
  let(:headers) do
    {
      idempotency_key: SecureRandom.uuid,
      correlation_id: SecureRandom.uuid,
      request_id: SecureRandom.uuid
    }
  end

  before { create(:vendor_user, vendor: vendor, user: actor) }

  def call_command(type, params = {}, idempotency_key: headers[:idempotency_key])
    described_class.call(
      vendor: vendor,
      actor: actor,
      command_type: type,
      idempotency_key: idempotency_key,
      correlation_id: headers[:correlation_id],
      request_id: headers[:request_id],
      params: params
    )
  end

  it 'creates a store idempotently' do
    first = call_command("create_store", { name: "Central Store", latitude: 6.5244, longitude: 3.3792 })
    replay = call_command("create_store", { name: "Different Name" })

    expect(replay["replayed"]).to eq(true)
    expect(Spree::VendorStore.where(vendor: vendor).count).to eq(1)
    expect(first["vendor_store_id"]).to eq(replay["vendor_store_id"])
  end

  it 'connects a provider-neutral payment account to a store' do
    store = create(:vendor_store, vendor: vendor, policy: { "geofence" => { "radius_m" => 100 } })

    result = call_command("connect_payment_account", {
      vendor_store_id: store.id,
      provider: "stripe",
      external_account_id: "acct_test_123",
      capabilities: { "transfers" => true },
      status: "ready"
    })

    expect(result["vendor_payment_account_id"]).to be_present
    expect(result["settlement_ready"]).to eq(true)
  end

  it 'does not allow an unrelated actor to mutate a vendor' do
    outsider = create(:user)

    expect {
      described_class.call(
        vendor: vendor,
        actor: outsider,
        command_type: "create_store",
        idempotency_key: SecureRandom.uuid,
        correlation_id: SecureRandom.uuid,
        request_id: SecureRandom.uuid,
        params: { name: "Denied Store" }
      )
    }.to raise_error(ActiveRecord::RecordNotFound, "Vendor access denied")
  end
end
