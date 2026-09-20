module Spree
  class AllocationLedgerEntry < Spree::Base
    self.table_name = 'spree_allocation_ledger_entries'

    belongs_to :plan_allocation, class_name: 'Spree::PlanAllocation'

    validates :entry_type, :currency, :idempotency_key, :correlation_id,
              :source_type, :source_reference, :occurred_at, presence: true
    validates :amount_cents, numericality: { greater_than: 0 }

    before_destroy { raise ActiveRecord::ReadOnlyRecord, 'allocation ledger is immutable' }

    def readonly?
      persisted?
    end
  end
end
