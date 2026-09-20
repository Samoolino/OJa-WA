class AddPostgisGeographyRegistry < ActiveRecord::Migration[7.2]
  def up
    enable_extension "postgis" unless extension_enabled?("postgis")

    create_table :spree_geographic_zones do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :level, null: false
      t.string :country_code, limit: 2
      t.string :parent_code
      t.jsonb :metadata, null: false, default: {}
      t.st_polygon :boundary, geographic: true, srid: 4326
      t.timestamps
    end

    add_index :spree_geographic_zones, [:level, :code], unique: true
    add_index :spree_geographic_zones, :parent_code
    add_index :spree_geographic_zones, :country_code
    add_index :spree_geographic_zones, :boundary, using: :gist

    create_table :spree_geo_audit_events do |t|
      t.string :operation_id, null: false
      t.string :correlation_id, null: false
      t.string :subject_type, null: false
      t.bigint :subject_id
      t.string :decision, null: false
      t.string :reason, null: false
      t.jsonb :evidence, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_index :spree_geo_audit_events, :operation_id, unique: true
    add_index :spree_geo_audit_events, :correlation_id
    add_index :spree_geo_audit_events, [:subject_type, :subject_id]
  end

  def down
    drop_table :spree_geo_audit_events
    drop_table :spree_geographic_zones
  end
end
