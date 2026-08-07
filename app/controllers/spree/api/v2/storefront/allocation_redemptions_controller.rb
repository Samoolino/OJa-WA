module Spree
  module Api
    module V2
      module Storefront
        class AllocationRedemptionsController < ::Spree::Api::V2::ResourceController
          def create
            plan_allocation = Spree::PlanAllocation.find(permitted_resource_params[:plan_allocation_id])
            user = Spree.user_class.find(permitted_resource_params[:user_id])
            redemption_code = params[:redemption_code]

            result = Spree::Plans::RedeemAllocation.call(plan_allocation: plan_allocation, user: user, redemption_code: redemption_code)

            if result.success?
              render json: result.redemption, status: :created
            else
              render json: { errors: result.errors }, status: :unprocessable_entity
            end
          end

          private

          def permitted_resource_params
            params.require(:allocation_redemption).permit(:plan_allocation_id, :user_id, :status, metadata: {})
          end
        end
      end
    end
  end
end
