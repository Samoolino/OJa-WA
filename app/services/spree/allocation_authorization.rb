module Spree
  class AllocationAuthorization
    Result = Struct.new(:allowed, :reason, :allocation, :ledger_entry, keyword_init: true)

    def self.reserve!(allocation:, amount_minor:, operation_id:, idempotency_key:, correlation_id:, context: {})
      new(
        allocation: allocation,
        amount_minor: amount_minor,
        operation_id: operation_id,
        idempotency_key: idempotency_key,
        correlation_id: correlation_id,
        context: context
      ).reserve!
    end

    def initialize(allocation:, amount_minor:, operation_id:, idempotency_key:, correlation_id:, context:)
      @allocation = allocation
      @amount_minor = Integer(amount_minor)
      @operation_id = operation_id.to_s
      @idempotency_key = idempotency_key.to_s
      @correlation_id = correlation_id.to_s
      @context = context.deep_symbolize_keys
    end

    def reserve!
      raise ArgumentError, 'amount_minor must be greater than zero' unless @amount_minor.positive?
      raise ArgumentError, 'operation_id is required' if @operation_id.empty?
      raise ArgumentError, 'idempotency_key is required' if @idempotency_key.empty?
      raise ArgumentError, 'correlation_id is required' if @correlation_id.empty?

      ActiveRecord::Base.transaction(requires_new: true) do
        allocation = Spree::PlanAllocation.lock.find(@allocation.id)

        existing = allocation.allocation_ledger_entries.find_by(idempotency_key: @idempotency_key)
        if existing
          return Result.new(
            allowed: existing.entry_type == 'reserve',
            reason: 'idempotent_replay',
            allocation: allocation,
            ledger_entry: existing
          )
        end

        reason = policy_failure(allocation)
        return Result.new(allowed: false, reason: reason, allocation: allocation) if reason

        if allocation.available_minor < @amount_minor
          return Result.new(allowed: false, reason: 'insufficient_available_allocation', allocation: allocation)
        end

        allocation.reserved_minor += @amount_minor
        allocation.save!

        entry = allocation.allocation_ledger_entries.create!(
          operation_id: @operation_id,
          idempotency_key: @idempotency_key,
          entry_type: 'reserve',
          amount_minor: @amount_minor,
          currency: allocation.currency,
          correlation_id: @correlation_id,
          metadata: @context,
          effective_at: Time.current
        )

        Result.new(allowed: true, reason: 'reserved', allocation: allocation, ledger_entry: entry)
      end
    end

    private

    def policy_failure(allocation)
      return 'allocation_not_active' unless allocation.active?
      return 'allocation_expired' if allocation.expires_at && allocation.expires_at <= Time.current

      policy = allocation.policy || {}
      return 'beneficiary_mismatch' if policy['user_id'].present? && policy['user_id'].to_s != @context[:user_id].to_s
      return 'purpose_mismatch' if policy['purpose'].present? && policy['purpose'].to_s != @context[:purpose].to_s
      return 'vendor_mismatch' if policy['vendor_id'].present? && policy['vendor_id'].to_s != @context[:vendor_id].to_s
      return 'store_mismatch' if policy['store_id'].present? && policy['store_id'].to_s != @context[:store_id].to_s
      return 'product_mismatch' if policy['product_ids'].present? && !Array(policy['product_ids']).map(&:to_s).include?(@context[:product_id].to_s)
      return 'geography_mismatch' if policy['geography'].present? && policy['geography'].to_s != @context[:geography].to_s
      return 'fulfillment_mismatch' if policy['fulfillment'].present? && policy['fulfillment'].to_s != @context[:fulfillment].to_s

      geo_policy = policy['geo_policy'] || allocation.metadata.to_h['geo_policy'] || {}
      if geo_policy.present?
        return 'geography_evidence_required' unless @context[:geo_authorized] == true
        return 'geography_evidence_invalid' unless @context[:geo_evidence].present?
      end

      nil
    end
  end
end
