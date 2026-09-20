module Spree
  class GeographicPolicyZone < Spree::Base
    CLASSIFICATIONS = %w[country state region lga district zone store].freeze

    validates :name, :classification, presence: true
    validates :classification, inclusion: { in: CLASSIFICATIONS }

    def contains_store?(store)
      return false unless boundary.present? && store.location.present?

      self.class.connection.select_value(
        self.class.sanitize_sql_array([
          "SELECT ST_Covers(?, ?)","boundary", "location"
        ])
      )
    end
  end
end
