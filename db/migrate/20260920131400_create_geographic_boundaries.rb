class CreateGeographicBoundaries < ActiveRecord::Migration[7.2]
  def change
    enable_extension "postgis" unless extension_enabled?("postgis")

    create_table :spree_geographic_boundaries do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :level, null: false
      t.string :country_code, limit: 2
      t.string :parent_code
      t.geometry :boundary, geographic: true, srid: 4326
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :spree_geographic_boundaries, :code, unique: true
    add_index :spree_geographic_boundaries, :parent_code
    add_index :spree_geographic_boundaries, :level
    add_index :spree_geographic_boundaries, :boundary, using: :gist
    add_check_constraint :spree_geographic_boundaries,
                         "level IN ('country','state','region','lga','district','zone','store')",
                         name: "geographic_boundary_level_check"
  end
end
