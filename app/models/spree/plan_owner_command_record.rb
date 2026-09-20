module Spree
  class PlanOwnerCommandRecord < Spree::Base
    belongs_to :plan_owner, class_name: Spree.user_class.name
    belongs_to :subscription_plan, class_name: 'Spree::SubscriptionPlan', optional: true

    validates :command_type, :idempotency_key, :correlation_id, :request_id, presence: true
    validates :idempotency_key, uniqueness: { scope: :plan_owner_id }

    def immutable?
      true
    end

    before_update { raise ActiveRecord::ReadOnlyRecord }
    before_destroy { raise ActiveRecord::ReadOnlyRecord }
  end
end
