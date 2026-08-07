module Spree
  module Admin
    class PlanOwnerPoliciesController < ResourceController
      private

      def collection
        @collection ||= Spree::PlanOwnerPolicy.order(created_at: :desc).page(params[:page]).per(params[:per_page])
      end

      def permitted_resource_params
        params.require(:plan_owner_policy).permit(:plan_owner_id, :vendor_id, :name, :description, :status, rules: {})
      end
    end
  end
end
