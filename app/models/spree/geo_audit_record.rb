module Spree
  class GeoAuditRecord < Spree::Base
    RESOLUTION_STATUSES = %w[UNRESOLVED RESOLVED INCONSISTENT REJECTED].freeze

    belongs_to :plan_allocation, optional: true
    belongs_to :vendor_store, optional: true

    validates :operation_id, :correlation_id, :latitude, :longitude, :effective_at, presence: true
    validates :operation_id, uniqueness: true
    validates :resolution_status, inclusion: { in: RESOLUTION_STATUSES }
    validate :coordinates_are_valid

    before_update { raise ActiveRecord::ReadOnlyRecord, "Geo audit records are immutable" }
    before_destroy { raise ActiveRecord::ReadOnlyRecord, "Geo audit records are immutable" }

    private

    def coordinates_are_valid
      return if latitude.nil? || longitude.nil?
      errors.add(:latitude, "must be between -90 and 90") unless latitude.to_f.between?(-90.0, 90.0)
      errors.add(:longitude, "must be between -180 and 180") unless longitude.to_f.between?(-180.0, 180.0)
    end
  end
end
