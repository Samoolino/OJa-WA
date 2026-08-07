module Spree
  module Api
    module V2
      module Storefront
        class SubscriptionPlansController < ::Spree::Api::V2::ResourceController
          private

          def collection
            @collection ||= Spree::SubscriptionPlan.active.order(created_at: :desc)
          end
        end
      end
    end
  end
end
