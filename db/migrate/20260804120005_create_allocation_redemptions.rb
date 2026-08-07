class CreateAllocationRedemptions < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_allocation_redemptions do |t|
      t.integer :plan_allocation_id
      t.integer :user_id
      t.string :redemption_code
      t.integer :status, default: 0, null: false
      t.datetime :redeemed_at
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :spree_allocation_redemptions, :plan_allocation_id
    add_index :spree_allocation_redemptions, :user_id
    add_index :spree_allocation_redemptions, :redemption_code, unique: true
  end
end
