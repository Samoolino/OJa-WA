module Spree
  module Plans
    class IssueCouponPayout
      prepend Spree::ServiceModule::Base

      def call(subscription_plan:, user:, vendor:, wallet_account:, amount_cents:, currency: 'USD')
        ActiveRecord::Base.transaction do
          payout = Spree::CouponPayout.create!(subscription_plan: subscription_plan,
                                              user: user,
                                              vendor: vendor,
                                              amount_cents: amount_cents,
                                              currency: currency,
                                              status: :issued,
                                              issued_at: Time.current)

          wallet_account.update!(balance_cents: wallet_account.balance_cents + amount_cents)
          Spree::AllocationAudit.create!(plan_allocation: nil,
                                         user: user,
                                         vendor: vendor,
                                         action: 'issue_coupon_payout',
                                         amount_cents: amount_cents,
                                         metadata: { coupon_code: payout.coupon_code })

          success(payout: payout)
        end
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end
    end
  end
end
