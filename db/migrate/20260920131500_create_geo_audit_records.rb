class CreateGeoAuditRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_geo_audit_records do |t|
      t.references :plan_allocation, foreign_key: { to_table: :spree_plan_allocations }, index: true
      t.references :vendor_store, foreign_key: { to_table: :spree_vendor_stores }, index: true
      t.string :operation_id, null: false
      t.string :correlation_id, null: false
      t.decimal :latitude, precision: 10, scale: 7, null: false
      t.decimal :longitude, precision: 10, scale: 7, null: false
      t.string :coordinate_source
      t.string :resolution_status, null: false, default: "UNRESOLVED"
      t.jsonb :resolved_hierarchy, null: false, default: {}
      t.jsonb :policy_result, null: false, default: {}
      t.datetime :effective_at, null: false
      t.timestamps
    end

    add_index :spree_geo_audit_records, :operation_id, unique: true
    add_index :spree_geo_audit_records, :correlation_id
    add_check_constraint :spree_geo_audit_records,
                         "latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180",
                         name: "geo_audit_coordinate_range_check"
    add_check_constraint :spree_geo_audit_records,
                         "resolution_status IN ('UNRESOLVED','RESOLVED','INCONSISTENT','REJECTED')",
                         name: "geo_audit_resolution_status_check"
  end
end
