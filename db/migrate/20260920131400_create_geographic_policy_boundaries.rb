class CreateGeographicPolicyBoundaries < ActiveRecord::Migration[7.2]
  def change
    enable_extension "postgis" unless extension_enabled?("postgis")

    create_table :spree_geographic_policy_boundaries do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :level, null: false
      t.string :country_code, limit: 2
      t.string :parent_code
      t.string :source
      t.string :source_version
      t.decimal :min_latitude, precision: 10, scale: 7
      t.decimal :max_latitude, precision: 10, scale: 7
      t.decimal :min_longitude, precision: 10, scale: 7
      t.decimal :max_longitude, precision: 10, scale: 7
      t.st_polygon :boundary, geographic: true, srid: 4326
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :spree_geographic_policy_boundaries, [:level, :code], unique: true,
              name: "idx_geo_boundaries_level_code"
    add_index :spree_geographic_policy_boundaries, :parent_code
    add_index :spree_geographic_policy_boundaries, :country_code
    add_index :spree_geographic_policy_boundaries, :boundary, using: :gist
    add_check_constraint :spree_geographic_policy_boundaries,
                         "level IN ('country','state','region','lga','district','zone','store')",
                         name: "geo_boundary_level_check"
  end
end
