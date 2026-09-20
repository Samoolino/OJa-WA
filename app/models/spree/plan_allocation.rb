module Spree
  class PlanAllocation < Spree::Base
    belongs_to :subscription_plan, class_name: 'Spree::SubscriptionPlan', optional: true
    belongs_to :user, class_name: Spree.user_class.name, optional: true
    belongs_to :vendor, class_name: 'Spree::Vendor', optional: true
    belongs_to :vendor_store, class_name: 'Spree::VendorStore', optional: true

    has_many :allocation_ledger_entries, class_name: 'Spree::AllocationLedgerEntry',
             foreign_key: :plan_allocation_id, inverse_of: :plan_allocation, dependent: :restrict_with_exception

    validates :allocation_code, presence: true, uniqueness: true
    validates :status, presence: true
    validates :funded_minor, :reserved_minor, :consumed_minor, :released_minor, :reversed_minor,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :currency, presence: true

    enum status: { pending: 0, active: 1, redeemed: 2, cancelled: 3 }

    before_validation :generate_code, on: :create

    def generate_code
      self.allocation_code ||= SecureRandom.alphanumeric(8).upcase
    end

    def available_minor
      funded_minor - reserved_minor - consumed_minor + released_minor + reversed_minor
    end

    def financially_consistent?
      [funded_minor, reserved_minor, consumed_minor, released_minor, reversed_minor].all?(&:nonnegative?) &&
        available_minor >= 0
    end
  end
end