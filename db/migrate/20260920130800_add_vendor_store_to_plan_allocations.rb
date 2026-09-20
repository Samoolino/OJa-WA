class AddVendorStoreToPlanAllocations < ActiveRecord::Migration[7.0]
  def change
    add_reference :spree_plan_allocations, :vendor_store,
                  foreign_key: { to_table: :spree_vendor_stores },
                  index: true
  end
end
