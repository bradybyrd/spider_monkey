################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe ComponentTemplate do
  before(:each) do
    User.current_user = User.find_by_login("admin")
    @app1 = create(:app)
    @app2 = create(:app)
    @component1 = create(:component)
    @component2 = create(:component)
    @application_component1 = create(:application_component, :app_id => @app1.id, :component_id => @component1.id)
    @application_component2 = create(:application_component, :app_id => @app1.id, :component_id => @component2.id)
    @application_component3 = create(:application_component, :app_id => @app2.id, :component_id => @component1.id)
    @application_component4 = create(:application_component, :app_id => @app2.id, :component_id => @component2.id)

  end

  describe "validations" do

    it "should validate presence of name" do
      @component_template1 = ComponentTemplate.new
      @component_template1.update_attributes({:app_id => @app1.id, :application_component_id => @application_component1.id})
      @component_template1.should_not be_valid
    end

    it "should validate presence of app_id" do
      @component_template1 = ComponentTemplate.new
      @component_template1.update_attributes({:name => 'ct001', :application_component_id => @application_component1.id})
      @component_template1.should_not be_valid
    end

    it "should validate presence of application_component_id" do
      @component_template1 = ComponentTemplate.new
      @component_template1.update_attributes({:name => 'ct001', :app_id => @app1.id})
      @component_template1.should_not be_valid
    end

    it "should be valid when required values are given" do
      @component_template1 = ComponentTemplate.new
      @component_template1.update_attributes({:app_id => @app1.id, :name => 'ct001', :application_component_id => @application_component1.id})
      @component_template1.should be_valid
    end

  end

  describe "associations" do

    it "should belong to" do
      @component_template1 = ComponentTemplate.new
      @component_template1.update_attributes({:app_id => @app1.id, :name => 'ct001', :application_component_id => @application_component1.id})
      @component_template1.should belong_to(:app)
      @component_template1.should belong_to(:application_component)
    end

  end

  describe "named scopes" do

    it "for_app" do
      @component_template1 = ComponentTemplate.new
      @component_template1.update_attributes({:app_id => @app1.id, :name => 'ct001', :application_component_id => @application_component1.id})
      ComponentTemplate.of_app(@app1.id).count.should == 1

      @component_template2 = ComponentTemplate.new
      @component_template2.update_attributes({:app_id => @app1.id, :name => 'ct002', :application_component_id => @application_component2.id})
      ComponentTemplate.of_app(@app1.id).count.should == 2
      ComponentTemplate.of_app(@app2.id).count.should == 0

      @component_template3 = ComponentTemplate.new
      @component_template3.update_attributes({:app_id => @app2.id, :name => 'ct003', :application_component_id => @application_component3.id})
      ComponentTemplate.of_app(@app1.id).count.should == 2
      ComponentTemplate.of_app(@app2.id).count.should == 1

    end

    it "active" do
      @initial_count = ComponentTemplate.active.count
      @component_template1 = ComponentTemplate.create(:app_id => @app1.id, :name => 'ct001', :application_component_id => @application_component1.id)
      @component_template1.active = false;
      ComponentTemplate.active.count.should == @initial_count

      @component_template2 = ComponentTemplate.create(:app_id => @app1.id, :name => 'ct002', :application_component_id => @application_component2.id, :active => true)
      ComponentTemplate.active.count.should == ( @initial_count + 1)

    end

  end

  describe "custom methods" do

    it "component_template_headers" do
      @component_template1 = ComponentTemplate.create(:app_id => @app1.id, :name => 'ct001', :application_component_id => @application_component1.id)
      @component_template1.component_template_headers.should == "'#{@app1.name}' '#{@application_component1.component.name}' '#{@component_template1.name}'"
    end

    it "is_active" do
      @component_template1 = ComponentTemplate.create(:app_id => @app1.id, :name => 'ct001', :application_component_id => @application_component1.id, :active => false)
      @component_template1.is_active?.should == "No"
      @component_template2 = ComponentTemplate.create(:app_id => @app1.id, :name => 'ct002', :application_component_id => @application_component2.id, :active => true)
      @component_template2.is_active?.should =="Yes"
    end

  end

end

