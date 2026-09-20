module Spree
  module Checkout
    class SettlementCommand
      Result = Struct.new(:eligible, :reason, :split, keyword_init: true)

      def self.evaluate(split:)
        new(split:).evaluate
      end

      def initialize(split:)
        @split = split
      end

      def evaluate
        split = Spree::CheckoutOrderSplit.find(@split.id)
        return Result.new(eligible: false, reason: "payment_not_captured", split:) unless split.captured?
        return Result.new(eligible: false, reason: "vendor_payment_account_not_ready", split:) unless store_or_vendor_account_ready?(split)
        return Result.new(eligible: false, reason: "fulfillment_not_confirmed", split:) unless fulfillment_ok?(split)
        return Result.new(eligible: false, reason: "transfer_idempotency_missing", split:) if split.transfer_idempotency_key.blank?
        return Result.new(eligible: false, reason: "reconciliation_exception", split:) if split.metadata.fetch("reconciliation_exception", false)

        Result.new(eligible: true, reason: "settlement_eligible", split:)
      end

      private

      def store_or_vendor_account_ready?(split)
        accounts = if split.vendor_store
          split.vendor_store.vendor_payment_accounts
        else
          split.vendor.vendor_payment_accounts
        end
        accounts.any?(&:settlement_ready?)
      end

      def fulfillment_ok?(split)
        !split.metadata.fetch("fulfillment_required", false) || split.fulfillment_status == "CONFIRMED"
      end
    end
  end
end
