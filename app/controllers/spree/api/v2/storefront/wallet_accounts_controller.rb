module Spree
  module Api
    module V2
      module Storefront
        class WalletAccountsController < ::Spree::Api::V2::ResourceController
          def create
            account = Spree::WalletAccount.new(permitted_resource_params)
            if account.save
              render json: account, status: :created
            else
              render json: { errors: account.errors.full_messages }, status: :unprocessable_entity
            end
          end

          private

          def permitted_resource_params
            params.require(:wallet_account).permit(:user_id, :vendor_id, :account_type, :status, :balance_cents, metadata: {})
          end
        end
      end
    end
  end
end
