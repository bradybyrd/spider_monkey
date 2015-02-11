require 'spec_helper'

describe Workstream do
  before(:each) do
    @workstream = Workstream.new
  end

  let(:Workstream_with_AllocationHelpers) {
    Workstream.new do
      include AllocationHelpers
    end
  }

  describe "validations" do
    before (:each) { create(:workstream) }
    it "validates presence of" do
      @workstream.should validate_presence_of(:resource_id)
      @workstream.should validate_presence_of(:activity_id)
    end
    it "validates uniqueness of" do
      @workstream.should validate_uniqueness_of(:activity_id).scoped_to(:resource_id)
    end
  end

  describe "associations" do
    it "belongs to" do
      @workstream.should belong_to(:resource)
      @workstream.should belong_to(:activity)
    end

    it "have many" do
      @workstream.should have_many(:resource_allocations)
    end
  end

  describe "delegations" do
    it { should delegate(:name).to(:activity) }
    it { should delegate(:name).to(:resource).with_options(:prefix => true) }
    it { should delegate(:role_names).to(:resource).with_options(:prefix => true) }
  end

end
