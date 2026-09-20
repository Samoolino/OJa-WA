class AddInstitutionalAllocationAccounting < ActiveRecord::Migration[7.0]
  def change
    change_table :spree_plan_allocations, bulk: true do |t|
      t.bigint :funded_minor, null: false, default: 0
      t.bigint :reserved_minor, null: false, default: 0
      t.bigint :consumed_minor, null: false, default: 0
      t.bigint :released_minor, null: false, default: 0
      t.bigint :reversed_minor, null: false, default: 0
      t.string :currency, null: false, default: 'USD'
      t.string :purpose
      t.jsonb :policy, null: false, default: {}
      t.string :kyc_requirement
      t.string :access_method, null: false, default: 'uuid'
      t.datetime :activated_at
      t.datetime :released_at
      t.datetime :reversed_at
    end

    add_index :spree_plan_allocations, %i[subscription_plan_id user_id status]
    add_check_constraint :spree_plan_allocations,
      'funded_minor >= 0 AND reserved_minor >= 0 AND consumed_minor >= 0 AND released_minor >= 0 AND reversed_minor >= 0',
      name: 'allocation_amounts_non_negative'
  end
end
