class AddFundingTargetMinorToSubscriptionPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_subscription_plans, :funding_target_minor, :bigint, null: false, default: 0
    add_check_constraint :spree_subscription_plans,
                         'funding_target_minor >= 0',
                         name: 'subscription_plans_funding_target_non_negative'
  end
end
