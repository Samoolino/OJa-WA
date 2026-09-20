require "digest"
require "json"

module Spree
  class PaymentEvidenceIngestion
    def self.call(provider:, provider_event_id:, event_type:, status:, correlation_id:, payload:, payment_reference: nil,
                  order_reference: nil, currency: nil, amount_minor: nil, occurred_at: nil)
      new(
        provider:, provider_event_id:, event_type:, status:, correlation_id:, payload:, payment_reference:,
        order_reference:, currency:, amount_minor:, occurred_at:
      ).call
    end

    def initialize(**attrs)
      @attrs = attrs
    end

    def call
      validate!
      fingerprint = self.class.fingerprint(@attrs[:payload])

      existing = Spree::PaymentEvidenceEvent.find_by(
        provider: @attrs[:provider],
        provider_event_id: @attrs[:provider_event_id]
      )
      if existing
        raise ArgumentError, "provider event payload mismatch" if existing.payload_fingerprint.present? && existing.payload_fingerprint != fingerprint
        return existing
      end

      Spree::PaymentEvidenceEvent.create!(@attrs.merge(payload_fingerprint: fingerprint))
    end

    def self.fingerprint(payload)
      Digest::SHA256.hexdigest(JSON.generate(canonicalize(payload)))
    end

    def self.canonicalize(value)
      case value
      when Hash
        value.keys.map(&:to_s).sort.to_h { |key| [key, canonicalize(value[key] || value[key.to_sym])] }
      when Array
        value.map { |item| canonicalize(item) }
      else
        value
      end
    end

    private

    def validate!
      raise ArgumentError, "provider_event_id is required" if @attrs[:provider_event_id].blank?
      raise ArgumentError, "correlation_id is required" if @attrs[:correlation_id].blank?
      if @attrs[:amount_minor].present? && Integer(@attrs[:amount_minor]).negative?
        raise ArgumentError, "amount_minor must not be negative"
      end
    end
  end
end
