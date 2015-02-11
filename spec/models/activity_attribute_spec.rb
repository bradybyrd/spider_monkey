require 'spec_helper'

describe ActivityAttribute do
  before(:all) do
    @activity_attribute = ActivityAttribute.new
  end

  let(:activity_attribute) { FactoryGirl.build(:activity_attribute) }

  describe "validations" do
    before(:each) { create(:activity_attribute) }
    it { @activity_attribute.should validate_presence_of(:name) }
    it { @activity_attribute.should validate_uniqueness_of(:name) }
  end

  describe "have_many" do
    context "should have many" do
      it { @activity_attribute.should have_many(:activity_tab_attributes) }
      it { @activity_attribute.should have_many(:activity_tabs) }
      it { @activity_attribute.should have_many(:activity_creation_attributes) }
      it { @activity_attribute.should have_many(:activity_attribute_values) }
    end
  end

  describe "scopes" do
    it "should have the scopes" do
      ActivityAttribute.should respond_to(:distinct_activity_category)
    end
  end

end

