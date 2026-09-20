module Spree
  class PaymentReconciliationCommand
    Result = Struct.new(:status, :record, keyword_init: true)

    def self.call(evidence:, expected_currency: nil, expected_amount_minor: nil, correlation_id:)
      new(evidence:, expected_currency:, expected_amount_minor:, correlation_id:).call
    end

    def initialize(evidence:, expected_currency:, expected_amount_minor:, correlation_id:)
      @evidence = evidence
      @expected_currency = expected_currency&.upcase
      @expected_amount_minor = expected_amount_minor.nil? ? nil : Integer(expected_amount_minor)
      @correlation_id = correlation_id.to_s
    end

    def call
      raise ArgumentError, "correlation_id is required" if @correlation_id.blank?

      observed_currency = @evidence.currency&.upcase
      observed_amount = @evidence.amount_minor

      status =
        if @expected_amount_minor.present? && observed_amount != @expected_amount_minor
          "AMOUNT_MISMATCH"
        elsif @expected_currency.present? && observed_currency != @expected_currency
          "CURRENCY_MISMATCH"
        elsif @evidence.provider_event_id.blank?
          "UNMATCHED"
        else
          "MATCHED"
        end

      record = Spree::PaymentReconciliationRecord.create!(
        provider: @evidence.provider,
        provider_event_id: @evidence.provider_event_id,
        payment_reference: @evidence.payment_reference,
        order_reference: @evidence.order_reference,
        status:,
        expected_currency: @expected_currency,
        expected_amount_minor: @expected_amount_minor,
        observed_currency:,
        observed_amount_minor: observed_amount,
        correlation_id: @correlation_id,
        metadata: { evidence_event_id: @evidence.id },
        resolved_at: status == "MATCHED" ? Time.current : nil
      )

      Result.new(status:, record:)
    rescue ActiveRecord::RecordNotUnique
      record = Spree::PaymentReconciliationRecord.find_by!(
        provider: @evidence.provider,
        provider_event_id: @evidence.provider_event_id
      )
      Result.new(status: record.status, record:)
    end
  end
end
