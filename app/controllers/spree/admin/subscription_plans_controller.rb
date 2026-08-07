module Spree
  module Admin
    class SubscriptionPlansController < ResourceController
      private

      def collection
        @collection ||= Spree::SubscriptionPlan.order(created_at: :desc).page(params[:page]).per(params[:per_page])
      end

      def permitted_resource_params
        params.require(:subscription_plan).permit(
          :name,
          :description,
          :status,
          :plan_type,
          :price_cents,
          :currency,
          :vendor_id,
          :plan_owner_id,
          :plan_owner_policy_id,
          eligibility_rules: {},
          payout_rules: {}
        )
      end
    end
  end
end
