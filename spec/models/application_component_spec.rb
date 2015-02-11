 ################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe ApplicationComponent do
  before(:each) do
    User.current_user = User.find_by_login("admin")

    @component1 = create(:component)
    @app1 = create(:app)

    @app_component = create(:application_component, :app => @app1, :component => @component1)
  end

  describe "when setting the insertion_point" do
    it "should insert the application component at that point" do
      @app_component.should_receive(:insert_at).with(42)
      @app_component.insertion_point = 42
    end
  end

  describe "when reading the insertion point" do
    it "should return the position" do
      @app_component.position = 42
      @app_component.insertion_point.should == @app_component.position
    end
  end

  describe "#literal_property_value_for" do
    before(:each) do
      @property = create(:property)
    end

    context "when there is a value on the application component" do
      it "returns that value" do
        create(:property_value, property: @property, value: "The value!", value_holder: @app_component)
        @app_component.component.properties = [@property]
        @app_component.literal_property_value_for(@property).should == "The value!"
      end
    end

    context "when there is not a value on the application component" do
      it "returns the property's default value" do
        @property.default_value = "Default value..."
        @app_component.literal_property_value_for(@property).should == "Default value..."
      end
    end

    it "should return current_property_values" do
      create(:property_value, :property => @property, :value => "The value!", :value_holder => @app_component)
      @app_component.current_property_values.should == @app_component.property_values
    end

  end


  describe "validations" do

    it "should validate the presence of component" do
      @app_component.component = nil
      @app_component.should_not be_valid
    end

    it "should validate the presence of app" do
      @app_component.app = nil
      @app_component.should_not be_valid
    end

    it "should be valid when app and components are given" do
      @app_component.should be_valid
    end


  end

  describe "associations" do

    it "should have many" do
      @app_component.should have_many(:installed_components)
      @app_component.should have_many(:application_environments)
      @app_component.should have_many(:property_values)
      @app_component.should have_many(:component_templates)
      @app_component.should have_many(:package_template_components)
      @app_component.should have_many(:package_template_items)
    end

    it "should belong to" do
      @app_component.should belong_to(:app)
      @app_component.should belong_to(:component)
    end

  end

  describe "delegates" do

    it "should have component's name" do
      @app_component.name.should == @component1.name
    end

  end

end

