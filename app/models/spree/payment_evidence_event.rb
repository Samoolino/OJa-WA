module Spree
  class PaymentEvidenceEvent < Spree::Base
    validates :provider, :provider_event_id, :event_type, :status, :correlation_id, presence: true
    validates :provider_event_id, uniqueness: { scope: :provider }

    before_update :prevent_mutation
    before_destroy :prevent_mutation

    private

    def prevent_mutation
      raise ActiveRecord::ReadOnlyRecord, "Payment evidence is immutable"
    end
  end
end
