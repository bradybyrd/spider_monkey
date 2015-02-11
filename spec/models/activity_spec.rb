require 'spec_helper'

describe Activity do
  before(:all) do
    @activity = Activity.new
  end

  describe "validations" do
    it { @activity.should validate_presence_of(:name) }
    it { @activity.should validate_presence_of(:activity_category_id) }
  end

  describe "belong_to" do
    context "should belong to" do
      it { @activity.should belong_to(:app) }
      it { @activity.should belong_to(:release) }
      it { @activity.should belong_to(:user) }
      it { @activity.should belong_to(:plan_stage) }
      it { @activity.should belong_to(:activity_category) }
      it { @activity.should belong_to(:current_phase) }
      it { @activity.should belong_to(:manager) }
      it { @activity.should belong_to(:leading_group) }
    end
  end

  describe "have_many" do
    context "should have many" do
      it { @activity.should have_many(:requests) }
      it { @activity.should have_many(:uploads) }
      it { @activity.should have_many(:workstreams) }
      it { @activity.should have_many(:resources) }
      it { @activity.should have_many(:placeholder_resources) }
      it { @activity.should have_many(:activity_attribute_values) }
      it { @activity.should have_many(:activity_tabs) }
      it { @activity.should have_many(:activity_phases) }
      it { @activity.should have_many(:deliverables) }
      it { @activity.should have_many(:notes) }
      it { @activity.should have_many(:updates) }
      it { @activity.should have_many(:index_columns) }
    end
  end

  describe "scopes" do
    it "should have the scopes" do
      Activity.should respond_to(:active)
      Activity.should respond_to(:request_compatible)
      Activity.should respond_to(:category_order)
      Activity.should respond_to(:roadmap_order)
      Activity.should respond_to(:with_placeholder_resources)
      Activity.should respond_to(:allocatable)
      Activity.should respond_to(:active_activities)
      Activity.should respond_to(:ongoing)
      Activity.should respond_to(:in_group)
      Activity.should respond_to(:no_group)
      Activity.should respond_to(:filtered_by_column)
      Activity.should respond_to(:in_category)
    end
  end

  describe "#shortcuts" do
    it "returns the Shortcuts ActivityAttributeValue" do
      activity = create_activity_with_shortcuts_value("This is a value")

      result = activity.shortcuts

      expect(result).to eq "This is a value"
    end

    it "sets the value of the Shortcuts ActivityAttributeValue" do
      activity = create_activity_with_shortcuts_value("haha, no")

      activity.shortcuts = "This is a new value"

      expect(activity.shortcuts).to eq "This is a new value"
    end

    def create_activity_with_shortcuts_value(shortcuts_value)
      activity_tab = create(:activity_tab)
      activity_category = activity_tab.activity_category
      activity = create(:activity, activity_category: activity_category)
      shortcuts_attribute = ActivityAttribute.where(name: "Shortcuts").first_or_create!
      activity_tab.activity_attributes << shortcuts_attribute
      activity_attribute_value = create(
        :activity_attribute_value,
        activity: activity,
        activity_attribute: shortcuts_attribute,
        value: shortcuts_value
      )
      activity
    end
  end

  describe "instance methods" do

    context "should be nil unless you use the :with_cost named_scope" do
      describe "projected_cost" do
        @activity = Activity.new
        @activity.projected_cost.should == @activity[:projected_cost]
      end

      describe "bottom_up_forecast" do
        @activity = Activity.new
        @activity.bottom_up_forecast.should == @activity[:bottom_up_forecast]
      end

      describe "year_end_forecast" do
        @activity = Activity.new
        @activity.year_end_forecast.should == @activity[:year_end_forecast]
      end

      describe "year_to_date_actual_spend" do
        @activity = Activity.new
        @activity.year_to_date_actual_spend.should == @activity[:year_to_date_actual_spend]
      end

      describe "approved_spend" do
        @activity = Activity.new
        @activity.approved_spend.should == @activity[:approved_spend]
      end
    end

  end


end
