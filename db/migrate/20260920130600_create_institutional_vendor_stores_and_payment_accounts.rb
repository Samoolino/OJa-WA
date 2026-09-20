class CreateInstitutionalVendorStoresAndPaymentAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_vendor_stores do |t|
      t.references :vendor, null: false, foreign_key: { to_table: :spree_vendors }
      t.string :name, null: false
      t.string :external_reference
      t.string :state, null: false, default: "draft"
      t.string :address
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.jsonb :policy, null: false, default: {}
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :spree_vendor_stores, [:vendor_id, :name], unique: true
    add_index :spree_vendor_stores, [:vendor_id, :external_reference], unique: true,
              where: "external_reference IS NOT NULL"

    create_table :spree_vendor_payment_accounts do |t|
      t.references :vendor, null: false, foreign_key: { to_table: :spree_vendors }
      t.references :vendor_store, foreign_key: { to_table: :spree_vendor_stores }
      t.string :provider, null: false
      t.string :external_account_id, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :capabilities, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :spree_vendor_payment_accounts, [:provider, :external_account_id], unique: true,
              name: "idx_vendor_payment_accounts_provider_external"
    add_index :spree_vendor_payment_accounts, [:vendor_id, :provider]
  end
end
