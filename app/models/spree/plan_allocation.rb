module Spree
  class PlanAllocation < Spree::Base
    belongs_to :subscription_plan, class_name: 'Spree::SubscriptionPlan', optional: true
    belongs_to :user, class_name: Spree.user_class.name, optional: true
    belongs_to :vendor, class_name: 'Spree::Vendor', optional: true

    validates :allocation_code, presence: true, uniqueness: true
    validates :status, presence: true

    enum status: { pending: 0, active: 1, redeemed: 2, cancelled: 3 }

    before_validation :generate_code, on: :create

    def generate_code
      self.allocation_code ||= SecureRandom.alphanumeric(8).upcase
    end
  end
end
