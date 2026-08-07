module Spree
  module Plans
    class AllocatePlan
      prepend Spree::ServiceModule::Base

      def call(plan:, user:, vendor:, wallet_account: nil)
        ActiveRecord::Base.transaction do
          allocation = Spree::PlanAllocation.create!(subscription_plan: plan,
                                                  user: user,
                                                  vendor: vendor,
                                                  status: :active,
                                                  allocated_at: Time.current)

          if wallet_account.present?
            allocate_from_wallet(wallet_account, allocation)
          end

          success(allocation: allocation)
        end
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end

      private

      def allocate_from_wallet(wallet_account, allocation)
        raise ActiveRecord::Rollback if wallet_account.balance_cents.zero?

        wallet_account.update!(balance_cents: wallet_account.balance_cents - allocation.subscription_plan.price_cents)
        Spree::AllocationAudit.create!(plan_allocation: allocation,
                                       user: allocation.user,
                                       vendor: allocation.vendor,
                                       action: 'allocate',
                                       amount_cents: allocation.subscription_plan.price_cents)
      end
    end
  end
end
