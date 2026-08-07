class CreatePlanOwnerPolicies < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_plan_owner_policies do |t|
      t.integer :plan_owner_id
      t.integer :vendor_id
      t.string :name
      t.text :description
      t.integer :status, default: 0, null: false
      t.jsonb :rules, default: {}
      t.timestamps
    end

    add_index :spree_plan_owner_policies, :plan_owner_id
    add_index :spree_plan_owner_policies, :vendor_id
  end
end
