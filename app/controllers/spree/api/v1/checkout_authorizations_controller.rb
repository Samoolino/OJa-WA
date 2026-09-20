module Spree
  module Api
    module V1
      class CheckoutAuthorizationsController < Spree::Api::BaseController
        def create
          allocation = Spree::PlanAllocation.find(params.require(:allocation_id))

          result = Spree::Checkout::AuthorizationCommand.call(
            allocation:,
            amount_minor: authorization_params.fetch(:amount_minor),
            currency: authorization_params.fetch(:currency),
            vendor_store_id: authorization_params.fetch(:vendor_store_id),
            product_skus: authorization_params.fetch(:product_skus),
            geo_context: authorization_params.fetch(:geo_context),
            correlation_id: request.headers["X-Correlation-Id"].presence || request.request_id
          )

          status = result.authorized ? :ok : :unprocessable_entity
          render json: {
            authorized: result.authorized,
            reason: result.reason,
            allocation_id: result.allocation.id
          }, status:
        rescue ActiveRecord::RecordNotFound
          render json: { authorized: false, reason: "allocation_not_found" }, status: :not_found
        rescue ActionController::ParameterMissing => e
          render json: { authorized: false, reason: e.message }, status: :unprocessable_entity
        end

        private

        def authorization_params
          params.require(:checkout).permit(
            :amount_minor,
            :currency,
            :vendor_store_id,
            product_skus: [],
            geo_context: [:geohash, :latitude, :longitude]
          )
        end
      end
    end
  end
end
