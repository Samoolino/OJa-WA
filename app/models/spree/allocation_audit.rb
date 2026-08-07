module Spree
  class AllocationAudit < Spree::Base
    belongs_to :plan_allocation, class_name: 'Spree::PlanAllocation', optional: true
    belongs_to :user, class_name: Spree.user_class.name, optional: true
    belongs_to :vendor, class_name: 'Spree::Vendor', optional: true

    validates :action, presence: true
    validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    enum status: { success: 0, failure: 1 }
  end
end
