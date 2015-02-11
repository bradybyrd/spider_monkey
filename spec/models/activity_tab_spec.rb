require 'spec_helper'

describe ActivityTab do
  before(:all) do
    @activity_tab = ActivityTab.new
  end

  describe "validations" do
    it { @activity_tab.should validate_presence_of(:name) }
    it { @activity_tab.should validate_presence_of(:activity_category_id) }
  end

  describe "associations" do
    context "should belong to" do
      it { @activity_tab.should belong_to(:activity_category) }
    end

    context "should have many" do
      it { @activity_tab.should have_many(:activity_tab_attributes) }
      it { @activity_tab.should have_many(:activity_attributes) }
    end
  end

end
