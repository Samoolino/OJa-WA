class CreateVendorCommandRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_vendor_command_records do |t|
      t.references :vendor, null: false, foreign_key: { to_table: :spree_vendors }
      t.references :vendor_store, foreign_key: { to_table: :spree_vendor_stores }
      t.string :command_type, null: false
      t.string :idempotency_key, null: false
      t.string :correlation_id, null: false
      t.string :request_id, null: false
      t.integer :resource_version
      t.jsonb :response_payload, null: false, default: {}
      t.timestamps
    end
    add_index :spree_vendor_command_records, [:vendor_id, :idempotency_key], unique: true,
              name: "idx_vendor_commands_vendor_idempotency"
    add_index :spree_vendor_command_records, [:vendor_id, :correlation_id]
  end
end
