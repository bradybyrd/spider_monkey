################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe ActivityCustomAttribute do

  describe 'validations' do
    describe 'validates_presence_of for input_type' do
      it 'should validate presence of input_type with incorrect value' do
        attr = build(:activity_custom_attribute, name: 'Attr', input_type: nil)
        expect(attr).to_not be_valid
        expect(attr.errors[:input_type].size).to be >= 1
      end

      it 'should validate presence of input_type with correct value' do
        attr = create(:activity_custom_attribute, name: 'Attr', input_type: 'multi_select')
        expect(attr).to be_valid
      end
    end
  end
  describe "#value_for" do
    before do
      @activity = create(:activity)
    end

    describe "for a multi-select" do
      it "is the the collected values of all the ActivityAttributeValues for the given activity and this attribute" do
        attr = create(:activity_custom_attribute, :name => 'Attr', :input_type => 'multi_select')
        @activity.activity_attribute_values.create! :activity_attribute_id => attr.id, :value => "val 1"
        @activity.activity_attribute_values.create! :activity_attribute_id => attr.id, :value => "val 2"
        attr.value_for(@activity).should include "val 1"
        attr.value_for(@activity).should include "val 2"
      end

      it "is [] when passed nil" do
        attr = create(:activity_custom_attribute, :name => "attr", :input_type => 'multi_select')
        attr.value_for(nil).should == []
      end
    end

    describe "for a single-value type" do
      it "is the value on the associated ActivityAttributeValue" do
        attr = create(:activity_custom_attribute, :name => "attr", :input_type => 'text_field')
        @activity.activity_attribute_values.create! :activity_attribute_id => attr.id, :value => 'the value'
        attr.value_for(@activity).should == 'the value'
      end

      it "is nil when passed nil" do
        attr = create(:activity_custom_attribute, :name => "attr", :input_type => 'text_field')
        attr.value_for(nil).should be_nil
      end
    end

  end

  describe "#pretty_value_for" do
    describe "for multi-selects" do
      it "is "" when given a nil activity" do
        ActivityCustomAttribute.new(:input_type => 'multi_select').value_for(nil).should == []
      end

      it "is a list of the objects' names for object associations" do
        group1 = create(:group, :name => "That Group")
        group2 = create(:group, :name => "That Other Group")
        attr = create(:activity_custom_attribute, :name => 'group', :input_type => 'multi_select', :attribute_values => ['Group'],
          :from_system => true)
        activity = create(:activity, :custom_attrs => { attr.id => [group1.id, group2.id] })
        attr.pretty_value_for(activity).should include "That Group"
        attr.pretty_value_for(activity).should include "That Other Group"
      end

      it "is unchanged otherwise" do
        attr = create(:activity_custom_attribute, :name => 'bacon surprise', :input_type => 'multi_select')
        activity = create(:activity, :custom_attrs => { attr.id => ["Surprise Bacon!", "And another thing..."] })
        attr.pretty_value_for(activity).should include "Surprise Bacon!"
        attr.pretty_value_for(activity).should include "And another thing..."
      end
    end

    describe "for single-value attributes" do
      it "is nil when given nil" do
        ActivityCustomAttribute.new.value_for(nil).should be_nil
      end

      it "is the name of the associated object for object associations" do
        group = create(:group, :name => "That Group")
        attr = create(:activity_custom_attribute, :name => 'group', :input_type => 'select', :attribute_values => ['Group'], :from_system => true)
        activity = create(:activity, :custom_attrs => { attr.id => group.id })
        attr.pretty_value_for(activity).should == "That Group"
      end

      it "is unchanged otherwise" do
        attr = create(:activity_custom_attribute, :name => 'bacon surprise', :input_type => 'text_field')
        activity = create(:activity, :custom_attrs => { attr.id => "Surprise Bacon!" })
        attr.pretty_value_for(activity).should == "Surprise Bacon!"
      end
    end

    describe "for date attributes with no value" do
      before do
        @attr = create(:activity_custom_attribute, :name => 'date', :input_type => 'date')
        @activity = create(:activity)
      end

      it "is '' when there is no value object" do
        @attr.pretty_value_for(@activity).should == ''
      end

      it "is '' when the value is set to ''" do
        @activity.update_attributes :custom_attrs => { @attr.id => '' }
        @attr.pretty_value_for(@activity).should == ''
      end

      it "is '' when the value is set to nil" do
        @activity.update_attributes :custom_attrs => { @attr.id => nil }
        @attr.pretty_value_for(@activity).should == ''
      end
    end
  end


end
