module Spree
  class VendorPaymentAccount < Spree::Base
    belongs_to :vendor, class_name: "Spree::Vendor"
    belongs_to :vendor_store, class_name: "Spree::VendorStore", optional: true

    validates :provider, :external_account_id, :status, presence: true
    validates :external_account_id, uniqueness: { scope: :provider }
    enum status: { pending: "pending", ready: "ready", restricted: "restricted", disabled: "disabled" }

    def settlement_ready?
      ready? && capabilities.fetch("transfers", false) == true
    end
  end
end
