class CreateSpreeAllocationFinancialRecords < ActiveRecord::Migration[7.0]
  def change
    change_table :spree_plan_allocations, bulk: true do |t|
      t.bigint :funded_cents, null: false, default: 0
      t.bigint :reserved_cents, null: false, default: 0
      t.bigint :consumed_cents, null: false, default: 0
      t.bigint :released_cents, null: false, default: 0
      t.bigint :reversed_cents, null: false, default: 0
      t.string :currency, null: false, default: 'USD'
    end

    create_table :spree_allocation_ledger_entries do |t|
      t.bigint :plan_allocation_id, null: false
      t.string :entry_type, null: false
      t.bigint :amount_cents, null: false
      t.string :currency, null: false
      t.string :idempotency_key, null: false
      t.string :correlation_id, null: false
      t.string :source_type, null: false
      t.string :source_reference, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_foreign_key :spree_allocation_ledger_entries, :spree_plan_allocations,
                    column: :plan_allocation_id
    add_index :spree_allocation_ledger_entries, :idempotency_key, unique: true
    add_index :spree_allocation_ledger_entries,
              [:plan_allocation_id, :entry_type, :idempotency_key],
              name: 'idx_spree_alloc_ledger_operation'
    add_check_constraint :spree_allocation_ledger_entries,
                         'amount_cents > 0',
                         name: 'spree_alloc_ledger_positive_amount'

    create_table :spree_funding_ingresses do |t|
      t.bigint :plan_allocation_id, null: false
      t.string :source_type, null: false
      t.string :source_reference, null: false
      t.string :provider, null: false
      t.string :status, null: false
      t.string :currency, null: false
      t.bigint :amount_cents, null: false
      t.string :idempotency_key, null: false
      t.string :correlation_id, null: false
      t.string :payload_fingerprint
      t.jsonb :evidence, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_foreign_key :spree_funding_ingresses, :spree_plan_allocations,
                    column: :plan_allocation_id
    add_index :spree_funding_ingresses, :idempotency_key, unique: true
    add_index :spree_funding_ingresses, [:provider, :source_reference], unique: true,
              name: 'idx_spree_funding_provider_reference'
    add_check_constraint :spree_funding_ingresses,
                         'amount_cents > 0',
                         name: 'spree_funding_positive_amount'
  end
end
