module Spree
  module Admin
    class AllocationAuditsController < ResourceController
      private

      def collection
        @collection ||= Spree::AllocationAudit.order(created_at: :desc).page(params[:page]).per(params[:per_page])
      end

      def permitted_resource_params
        params.require(:allocation_audit).permit(:plan_allocation_id, :user_id, :vendor_id, :action, :amount_cents, :status, metadata: {})
      end
    end
  end
end
