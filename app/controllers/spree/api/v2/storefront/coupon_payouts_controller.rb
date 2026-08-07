module Spree
  module Api
    module V2
      module Storefront
        class CouponPayoutsController < ::Spree::Api::V2::ResourceController
          def create
            payout = Spree::CouponPayout.new(permitted_resource_params)
            if payout.save
              render json: payout, status: :created
            else
              render json: { errors: payout.errors.full_messages }, status: :unprocessable_entity
            end
          end

          private

          def permitted_resource_params
            params.require(:coupon_payout).permit(:subscription_plan_id, :user_id, :vendor_id, :amount_cents, :currency, :status, :issued_at, :redeemed_at, metadata: {})
          end
        end
      end
    end
  end
end
