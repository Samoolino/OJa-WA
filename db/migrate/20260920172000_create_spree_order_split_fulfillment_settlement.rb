class CreateSpreeOrderSplitFulfillmentSettlement < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_order_splits do |t|
      t.string :order_reference, null: false
      t.string :cart_reference, null: false
      t.bigint :vendor_id, null: false
      t.bigint :vendor_store_id, null: false
      t.string :currency, null: false, limit: 3
      t.bigint :amount_cents, null: false
      t.string :status, null: false, default: "CREATED"
      t.string :payment_reference
      t.string :fulfillment_status, null: false, default: "PENDING"
      t.string :transfer_idempotency_key
      t.string :correlation_id, null: false
      t.jsonb :line_items, null: false, default: []
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :spree_order_splits, [:order_reference, :vendor_id, :vendor_store_id], unique: true, name: "idx_spree_order_splits_order_vendor_store"
    add_index :spree_order_splits, :cart_reference
    add_index :spree_order_splits, :payment_reference
    add_check_constraint :spree_order_splits, "amount_cents >= 0 AND vendor_id > 0 AND vendor_store_id > 0", name: "spree_order_splits_amount_identity_positive"

    create_table :spree_order_fulfillments do |t|
      t.bigint :order_id, null: false
      t.string :vendor_reference, null: false
      t.string :fulfillment_mode, null: false
      t.string :status, null: false, default: "pending"
      t.string :tracking_reference
      t.string :idempotency_key, null: false
      t.string :correlation_id
      t.jsonb :metadata, null: false, default: {}
      t.datetime :confirmed_at
      t.timestamps
    end
    add_index :spree_order_fulfillments, :idempotency_key, unique: true
    add_index :spree_order_fulfillments, [:order_id, :vendor_reference]

    create_table :spree_settlement_records do |t|
      t.bigint :order_id, null: false
      t.string :vendor_reference, null: false
      t.bigint :plan_allocation_id
      t.string :currency, null: false, limit: 3
      t.bigint :gross_amount_cents, null: false
      t.bigint :platform_fee_cents, null: false, default: 0
      t.bigint :net_amount_cents, null: false
      t.string :status, null: false, default: "created"
      t.string :correlation_id, null: false
      t.string :idempotency_key, null: false
      t.string :provider_reference
      t.string :connected_account_id
      t.jsonb :metadata, null: false, default: {}
      t.datetime :settled_at
      t.timestamps
    end
    add_index :spree_settlement_records, :idempotency_key, unique: true
    add_index :spree_settlement_records, [:order_id, :vendor_reference]
    add_check_constraint :spree_settlement_records, "gross_amount_cents >= 0 AND platform_fee_cents >= 0 AND net_amount_cents >= 0", name: "spree_settlement_amounts_nonnegative"
  end
end
