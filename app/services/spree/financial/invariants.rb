module Spree
  module Financial
    module Invariants
      module_function

      def available(allocation)
        value = allocation.funded_cents - allocation.reserved_cents -
                allocation.consumed_cents + allocation.released_cents +
                allocation.reversed_cents
        raise ActiveRecord::RecordInvalid.new(allocation), 'available balance cannot be negative' if value.negative?
        value
      end

      def assert_non_negative!(allocation)
        %i[funded_cents reserved_cents consumed_cents released_cents reversed_cents].each do |field|
          value = allocation.public_send(field)
          raise ActiveRecord::RecordInvalid.new(allocation), "#{field} cannot be negative" if value.negative?
        end
        available(allocation)
      end
    end
  end
end
