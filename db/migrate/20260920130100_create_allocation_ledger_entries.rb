class CreateAllocationLedgerEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_allocation_ledger_entries do |t|
      t.bigint :plan_allocation_id, null: false
      t.string :operation_id, null: false
      t.string :idempotency_key, null: false
      t.string :entry_type, null: false
      t.bigint :amount_minor, null: false
      t.string :currency, null: false
      t.string :source_type
      t.bigint :source_id
      t.string :correlation_id, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :effective_at, null: false
      t.timestamps
    end

    add_index :spree_allocation_ledger_entries, :plan_allocation_id
    add_index :spree_allocation_ledger_entries, :operation_id, unique: true
    add_index :spree_allocation_ledger_entries, %i[plan_allocation_id idempotency_key], unique: true,
      name: 'idx_allocation_ledger_allocation_idempotency'
    add_index :spree_allocation_ledger_entries, :correlation_id
    add_check_constraint :spree_allocation_ledger_entries,
      'amount_minor >= 0',
      name: 'allocation_ledger_amount_non_negative'
  end
end
