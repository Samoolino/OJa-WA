module Spree
  module Payment
    class EvidenceIngestion
      prepend Spree::ServiceModule::Base
      require 'digest'

      def call(plan_allocation:, provider:, provider_event_id:, amount_cents:, currency:,
               payload:, idempotency_key:, correlation_id:)
        fingerprint = Digest::SHA256.hexdigest(payload.to_json)
        existing = Spree::PaymentEvidenceEvent.find_by(provider: provider, provider_event_id: provider_event_id)
        if existing
          return failure(errors: ['payment evidence mismatch']) unless existing.payload_fingerprint == fingerprint
          return success(evidence: existing, replay: true)
        end

        evidence = Spree::PaymentEvidenceEvent.create!(
          plan_allocation: plan_allocation, provider: provider,
          provider_event_id: provider_event_id, amount_cents: amount_cents,
          currency: currency, payload_fingerprint: fingerprint,
          payload: payload, idempotency_key: idempotency_key,
          correlation_id: correlation_id, occurred_at: Time.current
        )
        success(evidence: evidence, replay: false)
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end
    end
  end
end
