module Spree
  class PaymentEvidenceEvent < Spree::Base
    self.table_name = 'spree_payment_evidence_events'
    belongs_to :plan_allocation, class_name: 'Spree::PlanAllocation'

    validates :provider, :provider_event_id, :payload_fingerprint, :currency,
              :idempotency_key, :correlation_id, presence: true
    validates :amount_cents, numericality: { greater_than: 0 }

    before_destroy { raise ActiveRecord::ReadOnlyRecord, 'payment evidence is immutable' }
    def readonly? = persisted?
  end
end
