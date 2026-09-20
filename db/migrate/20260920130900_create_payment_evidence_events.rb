class CreatePaymentEvidenceEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_payment_evidence_events do |t|
      t.string :provider, null: false
      t.string :provider_event_id, null: false
      t.string :event_type, null: false
      t.string :status, null: false
      t.string :payment_reference
      t.string :order_reference
      t.string :currency
      t.bigint :amount_minor
      t.string :correlation_id, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :occurred_at
      t.timestamps
    end

    add_index :spree_payment_evidence_events, [:provider, :provider_event_id],
              unique: true, name: "idx_payment_evidence_provider_event"
    add_index :spree_payment_evidence_events, :payment_reference
    add_index :spree_payment_evidence_events, :correlation_id
  end
end
