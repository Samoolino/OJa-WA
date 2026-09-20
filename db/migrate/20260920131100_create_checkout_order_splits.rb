class CreateCheckoutOrderSplits < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_checkout_order_splits do |t|
      t.string :cart_reference, null: false
      t.string :order_reference, null: false
      t.references :vendor, null: false, foreign_key: { to_table: :spree_vendors }
      t.references :vendor_store, foreign_key: { to_table: :spree_vendor_stores }
      t.string :currency, null: false
      t.bigint :amount_minor, null: false
      t.string :status, null: false, default: "CREATED"
      t.string :payment_reference
      t.string :fulfillment_status, null: false, default: "PENDING"
      t.string :transfer_idempotency_key
      t.string :correlation_id, null: false
      t.jsonb :line_items, null: false, default: []
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :spree_checkout_order_splits, [:order_reference, :vendor_id], unique: true,
              name: "idx_checkout_order_splits_order_vendor"
    add_index :spree_checkout_order_splits, :cart_reference
    add_index :spree_checkout_order_splits, :payment_reference
    add_index :spree_checkout_order_splits, :correlation_id
    add_check_constraint :spree_checkout_order_splits, "amount_minor >= 0",
                         name: "checkout_order_splits_amount_nonnegative"
  end
end
