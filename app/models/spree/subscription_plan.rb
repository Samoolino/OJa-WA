module Spree
  class SubscriptionPlan < Spree::Base
    belongs_to :plan_owner, class_name: 'Spree::User', optional: true
    belongs_to :vendor, class_name: 'Spree::Vendor', optional: true
    belongs_to :plan_owner_policy, class_name: 'Spree::PlanOwnerPolicy', optional: true

    has_many :plan_allocations, class_name: 'Spree::PlanAllocation', dependent: :destroy
    has_many :coupon_payouts, class_name: 'Spree::CouponPayout', dependent: :destroy

    validates :name, presence: true
    validates :price_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :currency, presence: true

    enum status: { draft: 0, active: 1, archived: 2 }
    enum plan_type: { one_time: 0, recurring: 1 }

    scope :active, -> { where(status: :active) }
  end
end