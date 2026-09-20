class CreateGeographicPolicyZones < ActiveRecord::Migration[7.2]
  def up
    enable_extension "postgis" unless extension_enabled?("postgis")

    create_table :spree_geographic_policy_zones do |t|
      t.string :name, null: false
      t.string :classification, null: false
      t.string :country_code
      t.string :state_code
      t.string :lga_code
      t.string :zone_code
      t.string :source
      t.string :source_version
      t.st_polygon :boundary, geographic: true, srid: 4326
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :spree_geographic_policy_zones, :classification
    add_index :spree_geographic_policy_zones, :country_code
    add_index :spree_geographic_policy_zones, :state_code
    add_index :spree_geographic_policy_zones, :lga_code
    add_index :spree_geographic_policy_zones, :zone_code
    add_index :spree_geographic_policy_zones, :boundary, using: :gist
    add_check_constraint :spree_geographic_policy_zones,
                         "classification IN ('country','state','region','lga','district','zone','store')",
                         name: "geographic_policy_zone_classification_check"
  end

  def down
    drop_table :spree_geographic_policy_zones
  end
end
