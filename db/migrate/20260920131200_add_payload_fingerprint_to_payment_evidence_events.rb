class AddPayloadFingerprintToPaymentEvidenceEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :spree_payment_evidence_events, :payload_fingerprint, :string, limit: 64

    add_index :spree_payment_evidence_events,
              [:provider, :provider_event_id, :payload_fingerprint],
              name: "idx_payment_evidence_provider_event_fingerprint"
  end
end
