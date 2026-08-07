module Spree
  module Api
    module V2
      module Storefront
        class PlanAllocationsController < ::Spree::Api::V2::ResourceController
          def create
            plan = Spree::SubscriptionPlan.find(permitted_resource_params[:subscription_plan_id])
            user = Spree.user_class.find(permitted_resource_params[:user_id])
            vendor = Spree::Vendor.find(permitted_resource_params[:vendor_id])
            wallet_account = Spree::WalletAccount.find_by(account_code: params[:wallet_account_code])

            result = Spree::Plans::AllocatePlan.call(plan: plan, user: user, vendor: vendor, wallet_account: wallet_account)

            if result.success?
              render json: result.allocation, status: :created
            else
              render json: { errors: result.errors }, status: :unprocessable_entity
            end
          end

          private

          def permitted_resource_params
            params.require(:plan_allocation).permit(:subscription_plan_id, :user_id, :vendor_id, :status, :allocated_at, :expires_at, metadata: {})
          end
        end
      end
    end
  end
end
