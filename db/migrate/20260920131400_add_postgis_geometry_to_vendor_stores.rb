class AddPostgisGeometryToVendorStores < ActiveRecord::Migration[7.2]
  def up
    enable_extension "postgis" unless extension_enabled?("postgis")

    add_column :spree_vendor_stores, :location, :st_point, geographic: true, srid: 4326
    add_index :spree_vendor_stores, :location, using: :gist
  end

  def down
    remove_index :spree_vendor_stores, :location
    remove_column :spree_vendor_stores, :location
  end
end
