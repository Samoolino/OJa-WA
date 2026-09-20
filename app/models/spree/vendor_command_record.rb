module Spree
  class VendorCommandRecord < Spree::Base
    belongs_to :vendor, class_name: "Spree::Vendor"
    belongs_to :vendor_store, class_name: "Spree::VendorStore", optional: true

    validates :command_type, :idempotency_key, :correlation_id, :request_id, presence: true
    validates :idempotency_key, uniqueness: { scope: :vendor_id }

    before_update :prevent_mutation
    before_destroy :prevent_mutation

    private

    def prevent_mutation
      raise ActiveRecord::ReadOnlyRecord, "Vendor command records are immutable"
    end
  end
end
