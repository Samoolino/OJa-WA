module Spree
  module Allocation
    class Reserve
      prepend Spree::ServiceModule::Base

      def call(plan_allocation:, user:, amount_cents:, currency:, idempotency_key:, correlation_id:,
               source_type: 'order', source_reference:, metadata: {})
        raise ArgumentError, 'amount_cents must be positive' unless amount_cents.to_i > 0
        raise ArgumentError, 'currency must be 3 letters' unless currency.to_s.match?(/\A[A-Z]{3}\z/)
        raise ArgumentError, 'idempotency_key is required' if idempotency_key.blank?
        raise ArgumentError, 'correlation_id is required' if correlation_id.blank?

        ActiveRecord::Base.transaction do
          allocation = Spree::PlanAllocation.lock.find(plan_allocation.id)
          prior = Spree::AllocationLedgerEntry.find_by(idempotency_key: idempotency_key)
          return success(allocation: allocation, ledger_entry: prior, replay: true) if prior

          return failure(errors: ['beneficiary mismatch']) unless allocation.user_id.nil? || allocation.user_id == user.id
          return failure(errors: ['allocation is not active']) unless allocation.active?
          return failure(errors: ['allocation has expired']) if allocation.expires_at.present? && allocation.expires_at <= Time.current
          return failure(errors: ['currency mismatch']) unless allocation.currency == currency
          return failure(errors: ['insufficient available balance']) if allocation.available_cents < amount_cents

          entry = Spree::AllocationLedgerEntry.create!(
            plan_allocation: allocation,
            entry_type: 'reserve',
            amount_cents: amount_cents,
            currency: currency,
            idempotency_key: idempotency_key,
            correlation_id: correlation_id,
            source_type: source_type,
            source_reference: source_reference,
            metadata: metadata.merge(beneficiary_id: user.id),
            occurred_at: Time.current
          )

          allocation.reserved_cents += amount_cents
          Spree::Financial::Invariants.assert_non_negative!(allocation)
          allocation.save!
          success(allocation: allocation, ledger_entry: entry, replay: false)
        end
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end
    end
  end
end
