module Spree
  module Api
    module V1
      class PaymentWebhooksController < Spree::Api::BaseController
        skip_before_action :verify_authenticity_token

        def create
          raw_payload = request.raw_post
          provider = params[:provider].to_s
          verification = Spree::PaymentProviderAdapter.verify_webhook(
            provider: provider,
            headers: request.headers,
            raw_payload: raw_payload
          )
          return render json: { accepted: false, error: verification.reason }, status: :unauthorized unless verification.verified

          payload = verification.payload.respond_to?(:to_hash) ? verification.payload.to_hash : JSON.parse(raw_payload)
          object = payload.dig("data", "object") || {}
          event = Spree::PaymentEvidenceIngestion.call(
            provider: provider,
            provider_event_id: payload.fetch("id"),
            event_type: payload.fetch("type"),
            status: object["status"] || "RECEIVED",
            correlation_id: request.headers["X-Correlation-Id"].presence || request.request_id,
            payload: payload,
            payment_reference: object["id"],
            order_reference: object.dig("metadata", "order_reference"),
            currency: object["currency"]&.upcase,
            amount_minor: object["amount"],
            occurred_at: Time.at(payload.fetch("created"))
          )

          render json: { accepted: true, event_id: event.id }, status: :accepted
        rescue JSON::ParserError, KeyError, ArgumentError => e
          render json: { accepted: false, error: e.message }, status: :unprocessable_entity
        end
      end
    end
  end
end
