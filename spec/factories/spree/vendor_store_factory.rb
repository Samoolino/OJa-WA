FactoryBot.define do
  factory :vendor_store, class: Spree::VendorStore do
    vendor
    sequence(:name) { |n| "Store #{n}" }
    state { "draft" }
    policy { {} }
  end
end
