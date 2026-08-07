class CreatePlanAllocations < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_plan_allocations do |t|
      t.integer :subscription_plan_id
      t.integer :user_id
      t.integer :vendor_id
      t.string :allocation_code
      t.integer :status, default: 0, null: false
      t.datetime :allocated_at
      t.datetime :expires_at
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :spree_plan_allocations, :subscription_plan_id
    add_index :spree_plan_allocations, :user_id
    add_index :spree_plan_allocations, :vendor_id
    add_index :spree_plan_allocations, :allocation_code, unique: true
  end
end
