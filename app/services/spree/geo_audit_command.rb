module Spree
  class GeoAuditCommand
    def self.record!(allocation:, store_id:, operation_id:, correlation_id:, latitude:, longitude:, coordinate_source:, resolution_status:, resolved_hierarchy:, policy_result:, effective_at: Time.current)
      Spree::GeoAuditRecord.create!(
        plan_allocation: allocation,
        vendor_store_id: store_id,
        operation_id:,
        correlation_id:,
        latitude:,
        longitude:,
        coordinate_source:,
        resolution_status:,
        resolved_hierarchy:,
        policy_result:,
        effective_at:
      )
    end
  end
end
