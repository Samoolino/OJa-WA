module Spree
  module Settlement
    class Eligibility
      prepend Spree::ServiceModule::Base
      def call(payment_captured:, vendor_account_ready:, fulfillment_required:, fulfillment_confirmed:, reconciliation_status:)
        return failure(errors: ["payment not captured"]) unless payment_captured
        return failure(errors: ["vendor settlement account not ready"]) unless vendor_account_ready
        return failure(errors: ["fulfillment not confirmed"]) if fulfillment_required && !fulfillment_confirmed
        return failure(errors: ["reconciliation not matched"]) unless reconciliation_status.to_s == "MATCHED"
        success(eligible: true)
      end
    end
  end
end
