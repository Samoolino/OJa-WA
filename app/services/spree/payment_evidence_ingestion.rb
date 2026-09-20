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
      existing = Spree::PaymentEvidenceEvent.find_by(
        provider: @attrs[:provider],
        provider_event_id: @attrs[:provider_event_id]
      )
      return existing if existing

      Spree::PaymentEvidenceEvent.create!(@attrs)
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
