module Spree
  module Allocation
    class LedgerOperation
      prepend Spree::ServiceModule::Base

      OP_FIELDS = {
        'consume' => [:reserved_cents, :consumed_cents],
        'release' => [:reserved_cents, :released_cents],
        'reverse' => [:consumed_cents, :reversed_cents]
      }.freeze

      def call(plan_allocation:, amount_cents:, currency:, operation:, idempotency_key:, correlation_id:,
               source_type:, source_reference:, metadata: {})
        raise ArgumentError, 'amount_cents must be positive' unless amount_cents.to_i > 0
        raise ArgumentError, 'unsupported operation' unless OP_FIELDS.key?(operation.to_s)
        raise ArgumentError, 'idempotency_key is required' if idempotency_key.blank?
        raise ArgumentError, 'correlation_id is required' if correlation_id.blank?

        ActiveRecord::Base.transaction do
          allocation = Spree::PlanAllocation.lock.find(plan_allocation.id)
          return failure(errors: ['currency mismatch']) unless allocation.currency == currency
          prior = Spree::AllocationLedgerEntry.find_by(idempotency_key: idempotency_key)
          return success(allocation: allocation, ledger_entry: prior, replay: true) if prior

          decrement, increment = OP_FIELDS.fetch(operation.to_s)
          if allocation.public_send(decrement) < amount_cents
            return failure(errors: ["#{decrement} insufficient"])
          end

          entry = Spree::AllocationLedgerEntry.create!(
            plan_allocation: allocation,
            entry_type: operation.to_s,
            amount_cents: amount_cents,
            currency: currency,
            idempotency_key: idempotency_key,
            correlation_id: correlation_id,
            source_type: source_type,
            source_reference: source_reference,
            metadata: metadata,
            occurred_at: Time.current
          )

          allocation[decrement] -= amount_cents
          allocation[increment] += amount_cents
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
