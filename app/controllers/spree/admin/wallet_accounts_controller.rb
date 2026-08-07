module Spree
  module Admin
    class WalletAccountsController < ResourceController
      private

      def collection
        @collection ||= Spree::WalletAccount.order(created_at: :desc).page(params[:page]).per(params[:per_page])
      end

      def permitted_resource_params
        params.require(:wallet_account).permit(:user_id, :vendor_id, :account_type, :status, :balance_cents, metadata: {})
      end
    end
  end
end
