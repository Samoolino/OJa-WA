module Spree
  module Api
    module V1
      class VendorManagementController < Spree::Api::V1::BaseController
        before_action :load_vendor

        def show
          render json: serialize_vendor
        end

        def command
          result = Spree::VendorOnboardingCommand.call(
            vendor: @vendor,
            actor: current_api_user,
            command_type: params.require(:command_type),
            idempotency_key: request.headers["Idempotency-Key"],
            correlation_id: request.headers["X-Correlation-Id"] || SecureRandom.uuid,
            request_id: request.request_id,
            params: command_params
          )
          render json: result, status: result["replayed"] ? :ok : :created
        rescue ActiveRecord::RecordNotFound
          render json: { error: "not_found" }, status: :not_found
        rescue ActiveRecord::RecordInvalid, ArgumentError => e
          render json: { error: "invalid_request", message: e.message }, status: :unprocessable_entity
        end

        private

        def load_vendor
          @vendor = Spree::Vendor.accessible_by(current_ability).find(params[:vendor_id])
        end

        def command_params
          params.fetch(:command, {}).permit(
            :name, :external_reference, :address, :latitude, :longitude,
            :vendor_store_id, :provider, :external_account_id, :status,
            policy: {}, capabilities: {}, metadata: {}
          )
        end

        def serialize_vendor
          {
            vendor_id: @vendor.id,
            name: @vendor.name,
            state: @vendor.state,
            stores: @vendor.vendor_stores.map do |store|
              {
                id: store.id,
                name: store.name,
                state: store.state,
                external_reference: store.external_reference,
                geo_configured: store.geo_configured?,
                vendor_payment_account_ids: store.vendor_payment_accounts.pluck(:id)
              }
            end,
            payment_accounts: @vendor.vendor_payment_accounts.map do |account|
              {
                id: account.id,
                provider: account.provider,
                external_account_id: account.external_account_id,
                status: account.status,
                settlement_ready: account.settlement_ready?
              }
            end
          }
        end
      end
    end
  end
end
