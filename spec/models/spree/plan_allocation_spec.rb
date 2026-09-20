require 'spec_helper'

RSpec.describe Spree::PlanAllocation do
  subject(:allocation) { described_class.new(funded_minor: 10_000, reserved_minor: 2_000, consumed_minor: 1_000, released_minor: 500, reversed_minor: 250, currency: 'USD') }

  it 'derives available allocation from immutable accounting components' do
    expect(allocation.available_minor).to eq(7_750)
    expect(allocation).to be_financially_consistent
  end

  it 'rejects a negative derived balance' do
    allocation.reserved_minor = 11_000

    expect(allocation).not_to be_financially_consistent
  end
end
