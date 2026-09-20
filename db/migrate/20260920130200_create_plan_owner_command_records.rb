class CreatePlanOwnerCommandRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_plan_owner_command_records do |t|
      t.integer :plan_owner_id, null: false
      t.integer :subscription_plan_id
      t.string :command_type, null: false
      t.string :idempotency_key, null: false
      t.string :correlation_id, null: false
      t.string :request_id, null: false
      t.integer :resource_version, null: false, default: 0
      t.jsonb :response_payload, null: false, default: {}
      t.timestamps
    end

    add_index :spree_plan_owner_command_records,
              [:plan_owner_id, :idempotency_key],
              unique: true,
              name: 'idx_plan_owner_commands_owner_idempotency'
    add_index :spree_plan_owner_command_records, :subscription_plan_id
    add_index :spree_plan_owner_command_records, :correlation_id
  end
end
