module Spree
  class SettlementRecord < Spree::Base
    STATUSES = %w[created eligible requested confirmed failed blocked].freeze
    validates :order_id, :vendor_reference, :currency, :gross_amount_cents, :net_amount_cents, :status, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :gross_amount_cents, :net_amount_cents, numericality: { greater_than_or_equal_to: 0 }
  end
end
