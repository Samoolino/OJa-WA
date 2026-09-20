class AddLockVersionToSubscriptionPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_subscription_plans, :lock_version, :integer, null: false, default: 0
  end
end
