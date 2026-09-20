module Spree
  class GeographicBoundary < Spree::Base
    LEVELS = %w[country state region lga district zone store].freeze

    validates :code, :name, :level, presence: true
    validates :code, uniqueness: true
    validates :level, inclusion: { in: LEVELS }

    scope :at_level, ->(level) { where(level:) }
    scope :children_of, ->(code) { where(parent_code: code) }
  end
end
