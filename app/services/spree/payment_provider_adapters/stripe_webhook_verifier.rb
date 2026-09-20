module Spree
  module PaymentProviderAdapters
    class StripeWebhookVerifier
      Result = Struct.new(:verified, :reason, :payload, keyword_init: true)

      def initialize(headers:, raw_payload:)
        @signature = headers["Stripe-Signature"] || headers["stripe-signature"]
        @raw_payload = raw_payload.to_s
      end

      def verify
        secret = ENV["STRIPE_WEBHOOK_SECRET"].to_s
        return Result.new(verified: false, reason: "webhook_secret_not_configured") if secret.blank?
        return Result.new(verified: false, reason: "signature_missing") if @signature.blank?

        event = Stripe::Webhook.construct_event(@raw_payload, @signature, secret)
        Result.new(verified: true, reason: "signature_verified", payload: event)
      rescue Stripe::SignatureVerificationError
        Result.new(verified: false, reason: "signature_invalid")
      rescue JSON::ParserError
        Result.new(verified: false, reason: "payload_invalid")
      end
    end
  end
end
