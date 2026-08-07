module Spree
  class AllocationRedemption < Spree::Base
    belongs_to :plan_allocation, class_name: 'Spree::PlanAllocation', optional: true
    belongs_to :user, class_name: Spree.user_class.name, optional: true

    validates :redemption_code, presence: true, uniqueness: true
    validates :status, presence: true

    enum status: { pending: 0, redeemed: 1, expired: 2 }

    before_validation :generate_code, on: :create

    def generate_code
      self.redemption_code ||= SecureRandom.alphanumeric(10).upcase
    end
  end
end
