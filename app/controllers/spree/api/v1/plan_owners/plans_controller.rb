module Spree
  module Api
    module V1
      module PlanOwners
        class PlansController < Spree::Api::V1::BaseController
          before_action :load_plan, only: [:show, :update, :allocation, :policy, :review, :activate]

          def create
            result = command('create')
            render_result(result, :created)
          rescue ArgumentError => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          def show
            render json: plan_payload(@plan)
          end

          def update
            render_result(command('update'), :ok)
          rescue ArgumentError => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          def allocation
            render_result(command('allocation'), :ok)
          rescue ArgumentError => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          def policy
            render_result(command('policy'), :ok)
          rescue ArgumentError => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          def review
            render_result(command('review'), :ok)
          rescue ArgumentError => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          def activate
            render_result(command('activate'), :ok)
          rescue ArgumentError => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          private

          def command(name)
            attributes = params[:plan].is_a?(ActionController::Parameters) ? params[:plan].to_unsafe_h : params[:plan]
            Spree::PlanOwner::OnboardingCommand.new(
              plan_owner: current_api_user,
              plan: @plan,
              command: name,
              attributes: attributes || {},
              idempotency_key: request.headers['Idempotency-Key'],
              correlation_id: request.headers['X-Correlation-Id'],
              request_id: request.request_id
            ).call
          end

          def load_plan
            @plan = Spree::SubscriptionPlan.find_by!(id: params[:id], plan_owner_id: current_api_user.id)
          rescue ActiveRecord::RecordNotFound
            render json: { error: 'PLAN_NOT_FOUND' }, status: :not_found
          end

          def render_result(result, status)
            render json: result.payload.merge(replayed: result.replayed?), status: status
          end

          def plan_payload(plan)
            {
              plan_id: plan.id,
              name: plan.name,
              objective: plan.description,
              currency: plan.currency,
              plan_type: plan.plan_type,
              funding_target_minor: plan.price_cents,
              status: plan.status,
              version: plan.lock_version,
              onboarding: Spree::PlanOwner::OnboardingCommand.new(
                plan_owner: current_api_user,
                plan: plan,
                command: 'review',
                attributes: {},
                idempotency_key: 'read-' + plan.id.to_s + '-' + plan.lock_version.to_s,
                correlation_id: request.request_id,
                request_id: request.request_id
              ).call.payload
            }
          end
        end
      end
    end
  end
end
