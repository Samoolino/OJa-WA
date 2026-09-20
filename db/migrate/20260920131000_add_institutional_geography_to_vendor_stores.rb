class AddInstitutionalGeographyToVendorStores < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_vendor_stores, :country_code, :string, limit: 2
    add_column :spree_vendor_stores, :admin_area_1_code, :string
    add_column :spree_vendor_stores, :admin_area_2_code, :string
    add_column :spree_vendor_stores, :locality, :string
    add_column :spree_vendor_stores, :postal_code, :string
    add_column :spree_vendor_stores, :timezone, :string
    add_column :spree_vendor_stores, :geocoding_source, :string
    add_column :spree_vendor_stores, :geocoding_accuracy, :string
    add_column :spree_vendor_stores, :geocoded_at, :datetime
    add_column :spree_vendor_stores, :geo_fence, :jsonb, null: false, default: {}

    add_index :spree_vendor_stores, [:country_code, :admin_area_1_code, :admin_area_2_code]
  end
end
