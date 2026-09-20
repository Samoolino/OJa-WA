module Spree
  module Fulfillment
    class Transition
      prepend Spree::ServiceModule::Base
      TRANSITIONS = {
        "pending" => %w[confirmed failed cancelled],
        "confirmed" => %w[failed cancelled],
        "failed" => [],
        "cancelled" => []
      }.freeze

      def call(fulfillment:, to:, correlation_id:)
        raise ArgumentError, "correlation_id is required" if correlation_id.blank?
        target = to.to_s
        return failure(errors: ["invalid fulfillment status"]) unless Spree::OrderFulfillment::STATUSES.include?(target)

        ActiveRecord::Base.transaction do
          record = Spree::OrderFulfillment.lock.find(fulfillment.id)
          return success(fulfillment: record, replay: true) if record.status == target
          return failure(errors: ["invalid fulfillment transition"]) unless TRANSITIONS.fetch(record.status, []).include?(target)

          record.status = target
          record.confirmed_at = Time.current if target == "confirmed"
          record.correlation_id = correlation_id
          record.save!
          success(fulfillment: record, replay: false)
        end
      rescue ActiveRecord::RecordInvalid => e
        failure(errors: e.record.errors.full_messages)
      end
    end
  end
end
