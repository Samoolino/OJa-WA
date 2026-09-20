Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :vendors do
      member do
        get :translations
        post :translations, to: 'vendors#edit_translations'
      end

      collection do
        post :update_positions
      end
    end

    resources :subscription_plans
    resources :plan_allocations
    resources :coupon_payouts
    resources :plan_owner_policies
    resources :wallet_accounts
    resources :allocation_audits, only: [:index, :show]

    get 'vendor_settings' => 'vendor_settings#edit'
    patch 'vendor_settings' => 'vendor_settings#update'
  end

  namespace :api, defaults: { format: 'json' } do
    namespace :v2 do
      namespace :storefront do
        resources :vendors, only: [:show,:index]
        resources :subscription_plans, only: [:index, :show]
        resources :plan_allocations, only: [:index, :show, :create]
        resources :coupon_payouts, only: [:index, :show, :create]
        resources :wallet_accounts, only: [:index, :show, :create]
        resources :allocation_redemptions, only: [:index, :show, :create]
        post 'wallet_transfers', to: 'wallet_transfers#create'
      end
    end

    namespace :v1 do
      resources :vendors
      namespace :plan_owners do
        resources :plans, only: [:create, :show, :update] do
          member do
            post :allocation
            post :policy
            post :review
            post :activate
          end
        end
      end
    end
  end
end
