module Spree
  class AllocationLedgerCommand
    Result = Struct.new(:applied, :reason, :allocation, :ledger_entry, keyword_init: true)

    ENTRY_DELTAS = {
      "consume" => { reserved_minor: -1, consumed_minor: 1 },
      "release" => { reserved_minor: -1, released_minor: 1 },
      "reverse" => { consumed_minor: -1, reversed_minor: 1 }
    }.freeze

    def self.call(allocation:, entry_type:, amount_minor:, operation_id:, idempotency_key:, correlation_id:, metadata: {})
      new(allocation:, entry_type:, amount_minor:, operation_id:, idempotency_key:, correlation_id:, metadata:).call
    end

    def initialize(allocation:, entry_type:, amount_minor:, operation_id:, idempotency_key:, correlation_id:, metadata:)
      @allocation = allocation
      @entry_type = entry_type.to_s
      @amount_minor = Integer(amount_minor)
      @operation_id = operation_id.to_s
      @idempotency_key = idempotency_key.to_s
      @correlation_id = correlation_id.to_s
      @metadata = metadata
    end

    def call
      validate!

      ActiveRecord::Base.transaction(requires_new: true) do
        allocation = Spree::PlanAllocation.lock.find(@allocation.id)
        existing = allocation.allocation_ledger_entries.find_by(idempotency_key: @idempotency_key)
        return Result.new(applied: false, reason: "idempotent_replay", allocation:, ledger_entry: existing) if existing

        deltas = ENTRY_DELTAS.fetch(@entry_type)
        validate_balance!(allocation, deltas)

        allocation.reserved_minor += deltas[:reserved_minor] * @amount_minor
        allocation.consumed_minor += deltas[:consumed_minor] * @amount_minor
        allocation.released_minor += deltas[:released_minor] * @amount_minor
        allocation.reversed_minor += deltas[:reversed_minor] * @amount_minor
        allocation.save!

        entry = allocation.allocation_ledger_entries.create!(
          operation_id: @operation_id,
          idempotency_key: @idempotency_key,
          entry_type: @entry_type,
          amount_minor: @amount_minor,
          currency: allocation.currency,
          correlation_id: @correlation_id,
          metadata: @metadata,
          effective_at: Time.current
        )

        Result.new(applied: true, reason: @entry_type, allocation:, ledger_entry: entry)
      end
    end

    private

    def validate!
      raise ArgumentError, "unsupported entry type" unless ENTRY_DELTAS.key?(@entry_type)
      raise ArgumentError, "amount_minor must be greater than zero" unless @amount_minor.positive?
      raise ArgumentError, "operation_id is required" if @operation_id.blank?
      raise ArgumentError, "idempotency_key is required" if @idempotency_key.blank?
      raise ArgumentError, "correlation_id is required" if @correlation_id.blank?
    end

    def validate_balance!(allocation, deltas)
      if deltas[:reserved_minor].negative? && allocation.reserved_minor < @amount_minor
        raise ArgumentError, "reserved balance is insufficient"
      end
      if deltas[:consumed_minor].negative? && allocation.consumed_minor < @amount_minor
        raise ArgumentError, "consumed balance is insufficient"
      end
    end
  end
end
