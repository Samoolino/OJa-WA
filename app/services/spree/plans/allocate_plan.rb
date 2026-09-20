module Spree
  module Plans
    class AllocatePlan
      prepend Spree::ServiceModule::Base

      def call(plan:, user:, vendor:, wallet_account: nil)
        ActiveRecord::Base.transaction(requires_new: true) do
          funding_minor = Integer(plan.respond_to?(:funding_target_minor) && plan.funding_target_minor.present? ? plan.funding_target_minor : plan.price_cents)
          raise ArgumentError, "allocation funding must be greater than zero" unless funding_minor.positive?

          allocation = Spree::PlanAllocation.create!(
            subscription_plan: plan,
            user: user,
            vendor: vendor,
            status: :active,
            funded_minor: 0,
            currency: plan.currency,
            purpose: plan.try(:description),
            allocated_at: Time.current
          )

          if wallet_account.present?
            raise ArgumentError, "wallet balance is insufficient" if wallet_account.balance_cents < funding_minor
            wallet_account.update!(balance_cents: wallet_account.balance_cents - funding_minor)
          end

          Spree::AllocationLedgerCommand.call(
            allocation: allocation,
            entry_type: "fund",
            amount_minor: funding_minor,
            operation_id: "allocation-funding:#{allocation.id}",
            idempotency_key: "allocation-funding:#{allocation.id}",
            correlation_id: "plan-allocation:#{allocation.id}",
            metadata: {
              "source_type" => "wallet_account",
              "source_id" => wallet_account&.id,
              "plan_id" => plan.id
            }.compact
          )

          success(allocation: allocation.reload)
        end
      rescue ActiveRecord::RecordInvalid, ArgumentError => e
        failure(errors: e.respond_to?(:record) && e.record ? e.record.errors.full_messages : [e.message])
      end
    end
  end
end
