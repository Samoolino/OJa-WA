class CreateSubscriptionPlans < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_subscription_plans do |t|
      t.integer :plan_owner_id
      t.integer :vendor_id
      t.string :name
      t.text :description
      t.integer :status, default: 0, null: false
      t.integer :plan_type, default: 0, null: false
      t.integer :price_cents, default: 0, null: false
      t.string :currency, default: 'USD', null: false
      t.jsonb :eligibility_rules, default: {}
      t.jsonb :payout_rules, default: {}
      t.timestamps
    end

    add_index :spree_subscription_plans, :plan_owner_id
    add_index :spree_subscription_plans, :vendor_id
  end
end
