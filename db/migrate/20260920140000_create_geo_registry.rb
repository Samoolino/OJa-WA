class CreateGeoRegistry < ActiveRecord::Migration[7.2]
  def change
    enable_extension "postgis" unless extension_enabled?("postgis")

    create_table :spree_geo_regions do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :classification, null: false
      t.references :parent, foreign_key: { to_table: :spree_geo_regions }
      t.st_point :centroid, geographic: true, srid: 4326
      t.st_polygon :boundary, geographic: true, srid: 4326
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :spree_geo_regions, :code, unique: true
    add_index :spree_geo_regions, :classification
    add_index :spree_geo_regions, :boundary, using: :gist
    add_check_constraint :spree_geo_regions,
                         "classification IN ('country','state','region','lga','district','zone')",
                         name: "geo_region_classification_check"

    create_table :spree_vendor_stores do |t|
      t.references :vendor, null: false, foreign_key: { to_table: :spree_vendors }
      t.string :store_code, null: false
      t.string :name, null: false
      t.string :status, null: false, default: "ACTIVE"
      t.st_point :location, geographic: true, srid: 4326, null: false
      t.references :geo_region, foreign_key: { to_table: :spree_geo_regions }
      t.string :address
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :spree_vendor_stores, [:vendor_id, :store_code], unique: true
    add_index :spree_vendor_stores, :location, using: :gist
  end
end
