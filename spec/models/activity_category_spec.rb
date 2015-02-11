require "spec_helper"

describe ActivityCategory do

  before(:each) do
    @activity_category = ActivityCategory.new
  end

  describe "validations" do
    it "should have name" do
      @activity_category.should validate_presence_of(:name)
    end
  end

  describe "associations" do
    it { @activity_category.should have_many(:activity_tabs) }
    it { @activity_category.should have_many(:activity_phases) }
    it { @activity_category.should have_many(:index_columns) }
    it { @activity_category.should have_many(:creation_attributes) }
    it { @activity_category.should have_many(:activities) }
  end

end