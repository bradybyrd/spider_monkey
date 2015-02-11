################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe ApplicationEnvironment do

  before do
    @user = create(:user, :admin => true)
  end

  before(:each) do

    User.stub(:current_user) { @user }
    @application1 = create(:app)
    @application2 = create(:app)

    @env1 = create(:environment, :id => 1004)
    @env2 = create(:environment, :id => 1005)

    @comp1 = create(:component)
    @comp2 = create(:component)

  end

  describe "named_scopes" do

    it "should have correct installed components" do
      @app_environment1 = create(:application_environment, :app => @application1, :environment => @env1)
      @app_component1 = create(:application_component, :app => @application1, :component => @comp1)
      @initial_count = ApplicationEnvironment.with_installed_components.count
      InstalledComponent.create(:application_environment_id => @app_environment1.id, :application_component_id => @app_component1.id)
      ApplicationEnvironment.with_installed_components.count.should == (@initial_count + 1)
    end

    it "named scope = having_environment_ids" do
      ApplicationEnvironment.having_environment_ids(1004).count.should == 0
      @app_environment2 = create(:application_environment, :app => @application1, :environment => @env1)
      ApplicationEnvironment.having_environment_ids(1004).count.should == 1
    end

    it "named scope :for_plan" do

      @app_environment1 = create(:application_environment, :app => @application1, :environment => @env1)
      @app_component1 = create(:application_component, :app => @application1, :component => @comp1)
      InstalledComponent.create(:application_environment_id => @app_environment1.id, :application_component_id => @app_component1.id)
      AssignedEnvironment.create!(:environment_id => @env1.id, :assigned_app_id => @application1.assigned_apps.first.id, :role => @user.roles.first)
      @request = create(:request, :scheduled_at => Time.now + 10.minutes, :auto_start => true, :apps => [@application1], :environment_id => @env1.id)
#      @request = create(:request, :aasm_state => 'created', :scheduled_at => 10.minutes.ago, :auto_start => true, :app_id => @application1.id)
      @request_template_1 = RequestTemplate.initialize_from_request(@request, {:name => "RT001"})

      @plan_template = create(:plan_template)
      @plan_stage_1 = create(:plan_stage, :plan_template => @plan_template, :name => "LT001")
      @plan_stage_2 = create(:plan_stage, :plan_template => @plan_template, :name => "LT002")

      @plan_stage_1.request_templates.push(@request_template_1)
      @plan_stage_2.request_templates.push(@request_template_1)

      @plan = create(:plan, :plan_template => @plan_template, :name => "LC001")

      results = ApplicationEnvironment.for_plan(@plan.id)
      results.length.should == 1
    end


    it "named_scope :acccessible_to_user" do
      @fresh_user = create(:user)
      @initial_value = ApplicationEnvironment.acccessible_to_user(@fresh_user).length
      @app_environment1 = create(:application_environment, :app => @application1, :environment => @env1)
      @app_environment1 = create(:application_environment, :app => @application2, :environment => @env2)
      @assigned_app1 = AssignedApp.create!(:app_id => @application1.id, :user_id => @fresh_user.id)
      @assigned_app2 = AssignedApp.create!(:app_id => @application2.id, :user_id => @fresh_user.id)
      @assigned_env1 = AssignedEnvironment.create!(:environment_id => @env1.id, :assigned_app_id => @assigned_app1.id, :role => @fresh_user.roles.first)
      @assigned_env2 = AssignedEnvironment.create!(:environment_id => @env2.id, :assigned_app_id => @assigned_app2.id, :role => @fresh_user.roles.first)
      results = ApplicationEnvironment.acccessible_to_user(@fresh_user)
      results.length.should == (2 + @initial_value)
    end

  end

  describe "custom methods" do

    it "should return default app and env" do
      @app_env_default1 = ApplicationEnvironment.associate_defaults
      @app_env_default2 = ApplicationEnvironment.associate_defaults

      @app_env_default1.id.should == @app_env_default2.id

    end


    it " should return correct name " do

      @test_name_app_environment = create(:application_environment, :app => @application1, :environment => @env1)
      @test_name_app_environment.name_label.should == @env1.name
    end


    it "should insert the appliction component at that point" do
      @test_insertion_app_environment = create(:application_environment, :app => @application1, :environment => @env1)
      @test_insertion_app_environment.should_receive(:insert_at).with(42)
      @test_insertion_app_environment.insertion_point = 42
    end

    it "should return the position when returning insertion point" do
      @test_insertion_app_environment = create(:application_environment, :app => @application1, :environment => @env1)
      @test_insertion_app_environment.position = 34
      @test_insertion_app_environment.insertion_point.should == @test_insertion_app_environment.position
    end

    it "should return installed component for given component" do
      @app_environment1 = create(:application_environment, :app => @application1, :environment => @env1)
      @app_component1 = create(:application_component, :app => @application1, :component => @comp1)
      @app_component2 = create(:application_component, :app => @application1, :component => @comp2)
      @installed_component1 = InstalledComponent.create(:application_environment_id => @app_environment1.id, :application_component_id => @app_component1.id)
      @installed_component2 = InstalledComponent.create(:application_environment_id => @app_environment1.id, :application_component_id => @app_component2.id)
      @app_environment1.installed_component_for(@comp1).should == @installed_component1
      @app_environment1.installed_component_for(@comp2).should == @installed_component2

    end

  end

  describe "associations" do

    it "should belong to" do
      @app_environment1 = create(:application_environment, :app => @application1, :environment => @env1)
      @app_environment1.should belong_to(:app)
      @app_environment1.should belong_to(:environment)
    end

    it "should have many" do
      @app_environment1 = create(:application_environment, :app => @application1, :environment => @env1)
      @app_environment1.should have_many(:installed_components)
      @app_environment1.should have_many(:application_components)
    end

  end

  describe "validations" do

    it "should validate required columns values" do
      @app_environment1 = create(:application_environment, :app => @application1, :environment => @env1)
      @app_environment1.should validate_presence_of(:app)
      @app_environment1.should validate_presence_of(:environment)
    end

  end

  describe "delegates" do

    it "should return environment's name" do
      @app_environment1 = create(:application_environment, :app => @application1, :environment => @env1)
      @app_environment1.name.should == @env1.name
    end


  end

  describe "when removing from an app" do

    before(:each) do
      User.current_user = create(:old_user)
      @environment = create(:environment)
      @app = create(:app)
      @app.environments << @environment
      @application_environment = ApplicationEnvironment.where(app_id: @app.id, environment_id: @environment.id).first
    end


    it "should allow removal from application with no requests" do
      expect { @application_environment.destroy }.to change(ApplicationEnvironment, :count)
    end

    it "should prevent removal from application with active requests" do
      AssignedEnvironment.create!(:environment_id => @environment.id, :assigned_app_id => @app.assigned_apps.first.id, :role => @user.roles.first)
      request = create(:request, :app_ids => [@app.id], :environment => @environment)
      expect { @application_environment.destroy }.not_to change(ApplicationEnvironment, :count)
    end

    it "should prevent removal from application with route gates" do
      route1 = create(:route, :app => @app)
      route_gate1 = create(:route_gate, :route => route1, :environment => @environment)
      @environment.reload
      @environment.routes.count.should == 2
      expect { @application_environment.destroy }.not_to change(ApplicationEnvironment, :count)
    end

  end


end
