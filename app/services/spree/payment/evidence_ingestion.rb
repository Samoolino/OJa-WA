module Spree
  module Payment
    class EvidenceIngestion
      prepend Spree::ServiceModule::Base
      require 'digest'
      require 'json'

      def call(plan_allocation:, provider:, provider_event_id:, amount_cents:, currency:,
               payload:, idempotency_key:, correlation_id:)
        fingerprint = Digest::SHA256.hexdigest(JSON.generate(canonical(payload || {})))
        existing = Spree::PaymentEvidenceEvent.find_by(provider: provider, provider_event_id: provider_event_id)
        if existing
          return failure(errors: ['payment evidence mismatch']) unless existing.payload_fingerprint == fingerprint
          return success(evidence: existing, replay: true)
        end

        observed_amount_cents = extract_amount_cents(payload)
        observed_currency = extract_currency(payload)
        return failure(errors: ['payment evidence amount is missing or invalid']) unless observed_amount_cents&.positive?
        return failure(errors: ['payment evidence currency is missing']) if observed_currency.blank?

        evidence = Spree::PaymentEvidenceEvent.create!(
          plan_allocation: plan_allocation, provider: provider,
          provider_event_id: provider_event_id, amount_cents: observed_amount_cents,
          currency: observed_currency, payload_fingerprint: fingerprint,
          payload: payload, idempotency_key: idempotency_key,
          correlation_id: correlation_id, occurred_at: Time.current
        )
        success(evidence: evidence, replay: false)
      rescue ActiveRecord::RecordNotUnique
        existing = Spree::PaymentEvidenceEvent.find_by(provider: provider, provider_event_id: provider_event_id)
        return failure(errors: ['payment evidence mismatch']) unless existing && existing.payload_fingerprint == fingerprint
        success(evidence: existing, replay: true)
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end

      private

      def extract_amount_cents(payload)
        value = payload['amount_cents'] || payload[:amount_cents] ||
                payload['amount'] || payload[:amount]
        Integer(value)
      rescue ArgumentError, TypeError
        nil
      end

      def extract_currency(payload)
        value = payload['currency'] || payload[:currency]
        value.to_s.upcase.presence
      end

      def canonical(value)
        case value
        when Hash
          value.keys.map(&:to_s).sort.each_with_object({}) do |key, h|
            h[key] = canonical(value[key] || value[key.to_sym])
          end
        when Array
          value.map { |item| canonical(item) }
        else
          value
        end
      end
    end
  end
end
