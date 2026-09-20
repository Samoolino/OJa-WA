module Spree
  class PaymentReconciliationRecord < Spree::Base
    STATUSES = %w[
      MATCHED UNMATCHED MISSING DUPLICATE
      AMOUNT_MISMATCH CURRENCY_MISMATCH TIMING_DIFFERENCE
    ].freeze

    validates :provider, :provider_event_id, :status, :correlation_id, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :provider_event_id, uniqueness: { scope: :provider }

    before_update :prevent_mutation
    before_destroy :prevent_mutation

    private

    def prevent_mutation
      raise ActiveRecord::ReadOnlyRecord, "reconciliation records are immutable"
    end
  end
end
