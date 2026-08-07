class CreateAllocationAudits < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_allocation_audits do |t|
      t.integer :plan_allocation_id
      t.integer :user_id
      t.integer :vendor_id
      t.string :action
      t.integer :amount_cents, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :spree_allocation_audits, :plan_allocation_id
    add_index :spree_allocation_audits, :user_id
    add_index :spree_allocation_audits, :vendor_id
  end
end
