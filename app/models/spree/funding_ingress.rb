module Spree
  class FundingIngress < Spree::Base
    self.table_name = 'spree_funding_ingresses'

    belongs_to :plan_allocation, class_name: 'Spree::PlanAllocation'

    validates :source_type, :source_reference, :provider, :status, :currency,
              :idempotency_key, :correlation_id, :occurred_at, presence: true
    validates :amount_cents, numericality: { greater_than: 0 }
    validates :status, inclusion: { in: %w[verified] }

    before_destroy { raise ActiveRecord::ReadOnlyRecord, 'funding evidence is immutable' }

    def readonly?
      persisted?
    end
  end
end
