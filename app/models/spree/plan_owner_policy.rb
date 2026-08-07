module Spree
  class PlanOwnerPolicy < Spree::Base
    belongs_to :plan_owner, class_name: Spree.user_class.name, optional: true
    belongs_to :vendor, class_name: 'Spree::Vendor', optional: true

    has_many :subscription_plans, class_name: 'Spree::SubscriptionPlan', dependent: :nullify

    validates :name, presence: true
    validates :status, presence: true

    enum status: { draft: 0, active: 1, suspended: 2 }

    def active?
      status == 'active'
    end
  end
end
