module Spree
  module Admin
    class PlanAllocationsController < ResourceController
      private

      def collection
        @collection ||= Spree::PlanAllocation.order(created_at: :desc).page(params[:page]).per(params[:per_page])
      end

      def permitted_resource_params
        params.require(:plan_allocation).permit(
          :subscription_plan_id,
          :user_id,
          :vendor_id,
          :status,
          :allocated_at,
          :expires_at,
          metadata: {}
        )
      end
    end
  end
end
