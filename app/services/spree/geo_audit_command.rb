module Spree
  class GeoAuditCommand
    def self.record!(allocation:, store_id:, operation_id:, correlation_id:, latitude:, longitude:, coordinate_source:, resolution_status:, resolved_hierarchy:, policy_result:, effective_at: Time.current)
      store = Spree::VendorStore.find_by(id: store_id) if store_id.present?
      raise ArgumentError, "vendor store not found" if store_id.present? && store.nil?
      if allocation.vendor_id.present? && store.present? && store.vendor_id != allocation.vendor_id
        raise ArgumentError, "vendor store does not belong to allocation vendor"
      end

      Spree::GeoAuditRecord.create!(
        plan_allocation: allocation,
        vendor_store_id: store&.id,
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
