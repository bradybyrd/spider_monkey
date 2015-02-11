require "spec_helper"

describe ResourceAllocation do

  before(:all) do
    @resource_allocation = ResourceAllocation.new
  end

  let(:ResourceAllocation_with_AllocationHelpers) {
    ResourceAllocation.new do
      include ResourceAllocation::AllocationHelpers
    end
  }

  describe "validations" do
    it { @resource_allocation.should validate_presence_of(:allocated_id) }
    it { @resource_allocation.should validate_presence_of(:allocated_type) }
    it { @resource_allocation.should validate_presence_of(:year) }
    it { @resource_allocation.should validate_presence_of(:month) }
    it { @resource_allocation.should validate_presence_of(:allocation) }
  end

  describe "associations" do
    it { @resource_allocation.should belong_to(:allocated) }
  end
end



