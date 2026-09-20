module Spree
  class ReconciliationRecord < Spree::Base
    self.table_name = 'spree_reconciliation_records'
    belongs_to :plan_allocation, class_name: 'Spree::PlanAllocation'

    validates :status, :expected_currency, :observed_currency, presence: true
    validates :expected_amount_cents, :observed_amount_cents, numericality: { greater_than: 0 }

    before_destroy { raise ActiveRecord::ReadOnlyRecord, 'reconciliation is immutable' }
    def readonly? = persisted?
  end
end
