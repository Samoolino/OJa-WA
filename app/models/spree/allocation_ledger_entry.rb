module Spree
  class AllocationLedgerEntry < Spree::Base
    self.table_name = 'spree_allocation_ledger_entries'

    belongs_to :plan_allocation, class_name: 'Spree::PlanAllocation'

    ENTRY_TYPES = %w[fund reserve consume release reverse].freeze

    validates :operation_id, :idempotency_key, :entry_type, :currency, :correlation_id, :effective_at, presence: true
    validates :amount_minor, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :entry_type, inclusion: { in: ENTRY_TYPES }
    validates :operation_id, uniqueness: true
    validates :idempotency_key, uniqueness: { scope: :plan_allocation_id }

    before_update { raise ActiveRecord::ReadOnlyRecord, 'allocation ledger entries are immutable' }
    before_destroy { raise ActiveRecord::ReadOnlyRecord, 'allocation ledger entries are immutable' }
  end
end
