module Spree
  module Plans
    class RedeemAllocation
      prepend Spree::ServiceModule::Base

      def call(plan_allocation:, user:, redemption_code: nil)
        ActiveRecord::Base.transaction do
          redemption = Spree::AllocationRedemption.create!(plan_allocation: plan_allocation,
                                                          user: user,
                                                          status: :redeemed,
                                                          redeemed_at: Time.current)

          plan_allocation.update!(status: :redeemed)
          Spree::AllocationAudit.create!(plan_allocation: plan_allocation,
                                         user: user,
                                         vendor: plan_allocation.vendor,
                                         action: 'redeem',
                                         amount_cents: plan_allocation.subscription_plan.price_cents,
                                         metadata: { redemption_code: redemption_code })

          success(redemption: redemption)
        end
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end
    end
  end
end
