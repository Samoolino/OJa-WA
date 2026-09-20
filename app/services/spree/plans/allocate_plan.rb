module Spree
  module Plans
    class AllocatePlan
      prepend Spree::ServiceModule::Base

      def call(plan:, user:, vendor:, wallet_account: nil, idempotency_key: nil, correlation_id: nil)
        correlation_id ||= SecureRandom.uuid
        ActiveRecord::Base.transaction do
          allocation = Spree::PlanAllocation.create!(
            subscription_plan: plan,
            user: user,
            vendor: vendor,
            status: :active,
            allocated_at: Time.current,
            currency: plan.currency.to_s.upcase
          )

          if wallet_account.present?
            amount = plan.price_cents.to_i
            raise ArgumentError, 'wallet account inactive' unless wallet_account.active?
            raise ArgumentError, 'insufficient wallet balance' if wallet_account.balance_cents < amount

            result = Spree::Funding::Issue.new.call(
              plan_allocation: allocation,
              amount_cents: amount,
              currency: allocation.currency,
              source_type: 'wallet',
              source_reference: wallet_account.account_code,
              provider: 'oja_wallet',
              status: 'verified',
              idempotency_key: idempotency_key || "allocation:#{allocation.id}:wallet",
              correlation_id: correlation_id,
              evidence: { wallet_account_id: wallet_account.id }
            )

            raise ActiveRecord::Rollback unless result.success?
            wallet_account.update!(balance_cents: wallet_account.balance_cents - amount)
          end

          success(allocation: allocation)
        end
      rescue ActiveRecord::RecordInvalid, ArgumentError => e
        failure(errors: [e.message])
      end
    end
  end
end
