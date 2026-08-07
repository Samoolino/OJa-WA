module Spree
  class CouponPayout < Spree::Base
    belongs_to :subscription_plan, class_name: 'Spree::SubscriptionPlan', optional: true
    belongs_to :user, class_name: Spree.user_class.name, optional: true
    belongs_to :vendor, class_name: 'Spree::Vendor', optional: true

    validates :coupon_code, presence: true, uniqueness: true
    validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :currency, presence: true

    enum status: { pending: 0, issued: 1, redeemed: 2, failed: 3 }

    before_validation :generate_code, on: :create

    def generate_code
      self.coupon_code ||= SecureRandom.alphanumeric(10).upcase
    end

    def display_amount
      (amount_cents / 100.0).round(2)
    end
  end
end
