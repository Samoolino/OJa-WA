module Spree
  class GeoAuditEventWriter
    def self.record!(correlation_id:, decision:, reason:, allocation_id: nil, store_id: nil, evidence: {})
      Spree::GeoAuditEvent.create!(
        correlation_id:,
        decision:,
        reason:,
        allocation_id:,
        store_id:,
        evidence:
      )
    end
  end
end
