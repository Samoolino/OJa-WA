class EnforceOneActiveAllocationPerBeneficiaryPlan < ActiveRecord::Migration[7.0]
  def change
    add_index :spree_plan_allocations,
              [:subscription_plan_id, :user_id],
              unique: true,
              where: "user_id IS NOT NULL AND status <> 3",
              name: 'idx_one_non_cancelled_allocation_per_beneficiary_plan'
  end
end
