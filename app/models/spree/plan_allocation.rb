module Spree
  class PlanAllocation < Spree::Base
    belongs_to :subscription_plan, class_name: 'Spree::SubscriptionPlan', optional: true
    belongs_to :user, class_name: Spree.user_class.name, optional: true
    belongs_to :vendor, class_name: 'Spree::Vendor', optional: true

    has_many :ledger_entries, class_name: 'Spree::AllocationLedgerEntry',
             dependent: :restrict_with_exception
    has_many :funding_ingresses, class_name: 'Spree::FundingIngress',
             dependent: :restrict_with_exception

    validates :allocation_code, presence: true, uniqueness: true
    validates :status, presence: true
    validates :funded_cents, :reserved_cents, :consumed_cents, :released_cents,
              :reversed_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }

    enum status: { pending: 0, active: 1, redeemed: 2, cancelled: 3 }

    before_validation :generate_code, on: :create

    def available_cents
      Spree::Financial::Invariants.available(self)
    end

    def generate_code
      self.allocation_code ||= SecureRandom.alphanumeric(8).upcase
    end
  end
end
