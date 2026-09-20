module Spree
  module PlanOwner
    class OnboardingCommand
      STEPS = %w[identity funding allocation policy review activation].freeze

      def initialize(plan_owner:, command:, plan: nil, attributes: {}, idempotency_key:, correlation_id:, request_id:)
        @plan_owner = plan_owner
        @command = command.to_s
        @plan = plan
        @attributes = attributes.to_h.deep_symbolize_keys
        @idempotency_key = idempotency_key.to_s
        @correlation_id = correlation_id.to_s
        @request_id = request_id.to_s
      end

      def call
        validate_request!
        existing = Spree::PlanOwnerCommandRecord.find_by(
          plan_owner: @plan_owner,
          idempotency_key: @idempotency_key
        )
        return Result.new(existing.response_payload, true) if existing

        response = ActiveRecord::Base.transaction(requires_new: true) do
          execute!
        end

        record = Spree::PlanOwnerCommandRecord.create!(
          plan_owner: @plan_owner,
          subscription_plan: @plan,
          command_type: @command,
          idempotency_key: @idempotency_key,
          correlation_id: @correlation_id,
          request_id: @request_id,
          resource_version: response.fetch(:version),
          response_payload: response
        )

        Result.new(response, false)
      rescue ActiveRecord::RecordNotUnique
        record = Spree::PlanOwnerCommandRecord.find_by!(
          plan_owner: @plan_owner,
          idempotency_key: @idempotency_key
        )
        Result.new(record.response_payload, true)
      end

      private

      def validate_request!
        raise ArgumentError, 'IDEMPOTENCY_KEY_REQUIRED' if @idempotency_key.blank?
        raise ArgumentError, 'CORRELATION_ID_REQUIRED' if @correlation_id.blank?
        raise ArgumentError, 'REQUEST_ID_REQUIRED' if @request_id.blank?
      end

      def execute!
        case @command
        when 'create'
          create_plan
        when 'update'
          update_plan
        when 'allocation'
          configure_allocation
        when 'policy'
          configure_policy
        when 'review'
          review_plan
        when 'activate'
          activate_plan
        else
          raise ArgumentError, 'UNKNOWN_COMMAND'
        end
      end

      def create_plan
        plan = Spree::SubscriptionPlan.new(
          plan_owner: @plan_owner,
          name: @attributes[:name],
          description: @attributes[:objective],
          currency: @attributes[:currency],
          plan_type: @attributes[:plan_type] || :one_time,
          price_cents: @attributes[:funding_target_minor] || 0,
          eligibility_rules: @attributes[:initial_policy] || {}
        )
        plan.save!
        @plan = plan
        response_for(plan)
      end

      def update_plan
        ensure_plan!
        ensure_draft!
        @plan.with_lock do
          expected = @attributes[:version]
          raise ArgumentError, 'PLAN_VERSION_CONFLICT' if expected.present? && expected.to_i != @plan.lock_version

          @plan.update!(
            name: @attributes[:name] || @plan.name,
            description: @attributes[:objective] || @plan.description,
            currency: @attributes[:currency] || @plan.currency,
            plan_type: @attributes[:plan_type] || @plan.plan_type,
            price_cents: @attributes[:funding_target_minor] || @plan.price_cents,
            eligibility_rules: merged_rules(@plan.eligibility_rules, @attributes[:configuration])
          )
        end
        response_for(@plan)
      end

      def configure_allocation
        ensure_plan!
        ensure_draft!
        @plan.with_lock do
          rules = @plan.eligibility_rules || {}
          rules['allocation'] = @attributes[:allocation] || {}
          @plan.update!(eligibility_rules: rules)
        end
        response_for(@plan)
      end

      def configure_policy
        ensure_plan!
        ensure_draft!
        @plan.with_lock do
          rules = @plan.eligibility_rules || {}
          rules['policy'] = @attributes[:policy] || {}
          @plan.update!(eligibility_rules: rules)
        end
        response_for(@plan)
      end

      def review_plan
        ensure_plan!
        result = onboarding_result(@plan)
        result.merge(proposed_plan_version: @plan.lock_version)
      end

      def activate_plan
        ensure_plan!
        raise ArgumentError, 'ACTIVATION_BLOCKED' unless onboarding_result(@plan)[:ready]
        @plan.with_lock do
          @plan.update!(status: :active)
        end
        response_for(@plan).merge(activation: 'ACTIVE')
      end

      def ensure_plan!
        raise ArgumentError, 'PLAN_NOT_FOUND' unless @plan
      end

      def ensure_draft!
        raise ArgumentError, 'PLAN_INVALID_STATE' unless @plan.draft?
      end

      def response_for(plan)
        {
          plan_id: plan.id,
          status: plan.status,
          version: plan.lock_version,
          onboarding_state: onboarding_result(plan)[:state],
          missing_requirements: onboarding_result(plan)[:missing_requirements],
          correlation_id: @correlation_id
        }
      end

      def onboarding_result(plan)
        rules = plan.eligibility_rules || {}
        allocation = rules['allocation'] || {}
        policy = rules['policy'] || {}
        missing = []
        missing << 'name' if plan.name.blank?
        missing << 'objective' if plan.description.blank?
        missing << 'currency' if plan.currency.blank?
        missing << 'funding_target_minor' if plan.price_cents.to_i <= 0
        missing << 'allocation' if allocation.blank?
        missing << 'beneficiary_access' if allocation['access_method'].blank?
        missing << 'policy' if policy.blank?

        state = if plan.active?
                  'ACTIVE'
                elsif missing.any?
                  'CONFIGURING'
                else
                  'REVIEW_READY'
                end

        { ready: missing.empty?, state: state, missing_requirements: missing }
      end

      def merged_rules(existing, incoming)
        (existing || {}).deep_merge((incoming || {}).deep_stringify_keys)
      end

      class Result
        attr_reader :payload
        def initialize(payload, replayed)
          @payload = payload
          @replayed = replayed
        end

        def replayed?
          @replayed
        end
      end
    end
  end
end
