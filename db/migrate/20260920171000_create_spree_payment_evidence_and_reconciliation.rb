class CreateSpreePaymentEvidenceAndReconciliation < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_payment_evidence_events do |t|
      t.bigint :plan_allocation_id, null: false
      t.string :provider, null: false
      t.string :provider_event_id, null: false
      t.bigint :amount_cents, null: false
      t.string :currency, null: false
      t.string :payload_fingerprint, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :idempotency_key, null: false
      t.string :correlation_id, null: false
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_foreign_key :spree_payment_evidence_events, :spree_plan_allocations, column: :plan_allocation_id
    add_index :spree_payment_evidence_events, [:provider, :provider_event_id], unique: true, name: 'idx_spree_payment_evidence_provider_event'
    add_index :spree_payment_evidence_events, :idempotency_key, unique: true

    create_table :spree_reconciliation_records do |t|
      t.bigint :plan_allocation_id, null: false
      t.bigint :expected_amount_cents, null: false
      t.string :expected_currency, null: false
      t.bigint :observed_amount_cents, null: false
      t.string :observed_currency, null: false
      t.string :status, null: false
      t.bigint :evidence_id, null: false
      t.string :idempotency_key, null: false
      t.string :correlation_id, null: false
      t.datetime :compared_at, null: false
      t.timestamps
    end
    add_foreign_key :spree_reconciliation_records, :spree_plan_allocations, column: :plan_allocation_id
    add_index :spree_reconciliation_records, :idempotency_key, unique: true
  end
end
