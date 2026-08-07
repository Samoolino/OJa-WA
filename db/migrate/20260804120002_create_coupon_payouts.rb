class CreateCouponPayouts < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_coupon_payouts do |t|
      t.integer :subscription_plan_id
      t.integer :user_id
      t.integer :vendor_id
      t.string :coupon_code
      t.integer :amount_cents, default: 0, null: false
      t.string :currency, default: 'USD', null: false
      t.integer :status, default: 0, null: false
      t.datetime :issued_at
      t.datetime :redeemed_at
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :spree_coupon_payouts, :subscription_plan_id
    add_index :spree_coupon_payouts, :user_id
    add_index :spree_coupon_payouts, :vendor_id
    add_index :spree_coupon_payouts, :coupon_code, unique: true
  end
end
