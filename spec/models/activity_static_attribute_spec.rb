################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe ActivityStaticAttribute do

  describe "#static?" do
    it "is true" do
      ActivityStaticAttribute.new.should be_static
    end
  end

  describe "#from_system?" do
    it "is true when the field ends with _id" do
      ActivityStaticAttribute.new(:field => 'current_phase_id').should be_from_system
    end

    it "is true when the field ends with _ids" do
      ActivityStaticAttribute.new(:field => 'parent_ids').should be_from_system
    end

    it "is false otherwise" do
      ActivityStaticAttribute.new.should_not be_from_system
    end
  end

  describe "for raw_values - #value_for" do
    it "is the value of the field on the activity" do
      activity = create(:activity, :name => "Activity of Awesomeness!")
      ActivityStaticAttribute.new(:field => 'name').value_for(activity).should == "Activity of Awesomeness!"
    end

    it "is the right date when the field is a date" do
      time = Time.zone.parse("1:00pm")
      activity = create(:activity, :projected_finish_at => time)
      ActivityStaticAttribute.new(:field => 'projected_finish_at', :input_type => 'date').value_for(activity).should == time
    end

    it "is nil when given a nil activity" do
      ActivityStaticAttribute.new(:field => 'name').value_for(nil).should be_nil
    end
  end

  describe "raw_values - #pretty_value_for" do
    it "is the name of the associated object for ids" do
      phase = create(:activity_phase, :name => "The Phase", :activity_category_id => create(:activity_category).id)
      activity = create(:activity, :current_phase => phase)
      attr = create(:activity_static_attribute, :name => 'phase', :input_type => 'select', :field => 'current_phase_id', :attribute_values => ['ActivityPhase'])
      attr.pretty_value_for(activity).should == "The Phase"
    end

    it "is a simple date for datetimes" do
      date = Date.parse("01/01/2013")
      activity = create(:activity, :projected_finish_at => date)
      attr = create(:activity_static_attribute, :name => 'finish', :input_type => 'date', :field => 'projected_finish_at')
      attr.pretty_value_for(activity).should == activity.projected_finish_at.strftime('%m/%d/%Y')
    end

    it "is unchanged otherwise" do
      activity = create(:activity, :name => "The Activity")
      attr = create(:activity_static_attribute, :name => 'name', :input_type => 'text_field', :field => 'name')
      attr.pretty_value_for(activity).should == "The Activity"
    end

    describe "for date attributes with no value" do
      before do
        @attr = create(:activity_static_attribute, :name => 'date', :input_type => 'date', :field => 'projected_finish_at')
        @activity = create(:activity)
      end

      it "is '' when the value is nil" do
        @activity.update_attributes :projected_finish_at => nil
        @attr.pretty_value_for(@activity).should == ''
      end
    end
  end
end
