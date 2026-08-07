module Spree
  module Api
    module V2
      module Storefront
        class WalletTransfersController < ::Spree::Api::V2::ResourceController
          def create
            source_account = Spree::WalletAccount.find_by(account_code: params[:source_account_code])
            target_account = Spree::WalletAccount.find_by(account_code: params[:target_account_code])
            amount_cents = params[:amount_cents].to_i

            source_account.transfer_to!(target_account, amount_cents)

            render json: { status: 'ok' }, status: :created
          rescue StandardError => e
            render json: { errors: [e.message] }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
