module Spree
  module Admin
    class CouponPayoutsController < ResourceController
      private

      def collection
        @collection ||= Spree::CouponPayout.order(created_at: :desc).page(params[:page]).per(params[:per_page])
      end

      def permitted_resource_params
        params.require(:coupon_payout).permit(
          :subscription_plan_id,
          :user_id,
          :vendor_id,
          :amount_cents,
          :currency,
          :status,
          :issued_at,
          :redeemed_at,
          metadata: {}
        )
      end
    end
  end
end
