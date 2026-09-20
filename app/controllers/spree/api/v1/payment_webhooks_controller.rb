module Spree
  module Api
    module V1
      class PaymentWebhooksController < Spree::Api::BaseController
        skip_before_action :verify_authenticity_token

        def create
          raw_payload = request.raw_post
          payload = JSON.parse(raw_payload)
          provider = params[:provider].to_s

          event = Spree::PaymentEvidenceIngestion.call(
            provider:,
            provider_event_id: payload.fetch("id"),
            event_type: payload.fetch("type"),
            status: payload.dig("data", "object", "status") || payload["status"] || "RECEIVED",
            correlation_id: request.headers["X-Correlation-Id"].presence || request.request_id,
            payload:,
            payment_reference: payload.dig("data", "object", "id"),
            order_reference: payload.dig("data", "object", "metadata", "order_reference"),
            currency: payload.dig("data", "object", "currency")&.upcase,
            amount_minor: payload.dig("data", "object", "amount"),
            occurred_at: Time.at(payload.fetch("created")) rescue nil
          )

          render json: { accepted: true, event_id: event.id }, status: :accepted
        rescue JSON::ParserError, KeyError, ArgumentError => e
          render json: { accepted: false, error: e.message }, status: :unprocessable_entity
        end
      end
    end
  end
end
