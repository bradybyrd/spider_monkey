require 'spec_helper'

describe ActivityPhase do
  before(:each) do
    @activity_phase = ActivityPhase.new
  end

  describe "validations" do
    before(:each) { create(:activity_phase) }
    it { @activity_phase.should validate_presence_of(:name) }
    it { @activity_phase.should validate_uniqueness_of(:name).scoped_to(:activity_category_id) }
    it { @activity_phase.should validate_presence_of(:activity_category_id) }
  end

  describe "associations" do
    it "should belong to" do
      @activity_phase.should belong_to(:activity_category)
    end

    it "should have many" do
      @activity_phase.should have_many(:deliverables)
    end
  end

  describe "scopes" do
    it "should have the scopes" do
      ActivityPhase.should respond_to(:in_order)
    end
  end

  it "should have insertion point" do
    @activity_phase.insertion_point.should == @activity_phase.position
  end

end

