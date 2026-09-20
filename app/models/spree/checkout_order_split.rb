module Spree
  class CheckoutOrderSplit < Spree::Base
    belongs_to :vendor, class_name: "Spree::Vendor"
    belongs_to :vendor_store, class_name: "Spree::VendorStore", optional: true

    STATUSES = %w[CREATED REQUIRES_METHOD REQUIRES_AUTH PROCESSING AUTHORIZED CAPTURED FAILED CANCELLED REFUNDED DISPUTED SETTLED].freeze
    FULFILLMENT_STATUSES = %w[PENDING CONFIRMED FAILED].freeze

    validates :cart_reference, :order_reference, :currency, :correlation_id, presence: true
    validates :amount_minor, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :status, inclusion: { in: STATUSES }
    validates :fulfillment_status, inclusion: { in: FULFILLMENT_STATUSES }

    def captured?
      status == "CAPTURED"
    end

    def settlement_eligible?
      captured? &&
        vendor_payment_account_ready? &&
        fulfillment_requirement_satisfied? &&
        transfer_idempotency_key.present?
    end

    private

    def vendor_payment_account_ready?
      vendor.vendor_payment_accounts.any?(&:settlement_ready?)
    end

    def fulfillment_requirement_satisfied?
      metadata.fetch("fulfillment_required", false) == false || fulfillment_status == "CONFIRMED"
    end
  end
end
