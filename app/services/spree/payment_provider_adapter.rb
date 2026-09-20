module Spree
  class PaymentProviderAdapter
    Result = Struct.new(:verified, :reason, :evidence, keyword_init: true)

    PROVIDERS = %w[stripe].freeze

    def self.verify_webhook(provider:, headers:, raw_payload:)
      new(provider:, headers:, raw_payload:).verify_webhook
    end

    def initialize(provider:, headers:, raw_payload:)
      @provider = provider.to_s.downcase
      @headers = headers
      @raw_payload = raw_payload.to_s
    end

    def verify_webhook
      return Result.new(verified: false, reason: "unsupported_provider") unless PROVIDERS.include?(@provider)

      verifier = Spree::PaymentProviderAdapters::StripeWebhookVerifier.new(
        headers: @headers,
        raw_payload: @raw_payload
      )
      verifier.verify
    end
  end
end
