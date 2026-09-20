module Spree
  class PaymentEvidenceProjection
    PAYMENT_STATUSES = {
      "requires_payment_method" => "REQUIRES_METHOD",
      "requires_action" => "REQUIRES_AUTH",
      "processing" => "PROCESSING",
      "authorized" => "AUTHORIZED",
      "succeeded" => "CAPTURED",
      "failed" => "FAILED",
      "canceled" => "CANCELLED",
      "refunded" => "REFUNDED",
      "disputed" => "DISPUTED"
    }.freeze

    def self.status_for(evidence_status)
      PAYMENT_STATUSES[evidence_status.to_s.downcase] || evidence_status.to_s.upcase
    end

    def self.call(evidence:, expected_currency: nil, expected_amount_minor: nil)
      reconciliation = Spree::PaymentReconciliationCommand.call(
        evidence:,
        expected_currency:,
        expected_amount_minor:,
        correlation_id: evidence.correlation_id
      )

      {
        payment_status: status_for(evidence.status),
        reconciliation_status: reconciliation.status,
        payment_reference: evidence.payment_reference,
        order_reference: evidence.order_reference,
        correlation_id: evidence.correlation_id
      }
    end
  end
end
