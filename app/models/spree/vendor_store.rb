module Spree
  class VendorStore < Spree::Base
    belongs_to :vendor, class_name: "Spree::Vendor"
    has_many :vendor_payment_accounts, class_name: "Spree::VendorPaymentAccount", dependent: :restrict_with_exception
    has_many :plan_allocations, class_name: "Spree::PlanAllocation", foreign_key: :vendor_store_id, dependent: :restrict_with_exception

    enum state: { draft: "draft", pending: "pending", active: "active", blocked: "blocked" }

    validates :name, presence: true, uniqueness: { scope: :vendor_id, case_sensitive: false }
    validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
    validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
    validates :country_code, length: { is: 2 }, allow_nil: true

    def geo_configured?
      latitude.present? && longitude.present?
    end

    def geographic_classification
      {
        country_code: country_code,
        admin_area_1_code: admin_area_1_code,
        admin_area_2_code: admin_area_2_code,
        locality: locality,
        postal_code: postal_code,
        timezone: timezone
      }.compact
    end

    def geofence_configured?
      geo_fence.present? && geo_fence != {}
    end
  end
end
