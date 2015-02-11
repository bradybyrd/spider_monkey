################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################
require 'spec_helper'

describe AssignedEnvironment do

  before(:each) do

    User.current_user = User.find_by_login("admin")
    @app1 = create(:app, :name => 'app1')
    @app2 = create(:app, :name => 'app2')
    @user1 = create(:user, :login => 'rspecuser')
    @assigned_app1 = AssignedApp.create(:user_id => @user1.id, :app_id => @app1.id)
    @assigned_app2 = AssignedApp.create(:user_id => @user1.id, :app_id => @app2.id)
    @env1 = create(:environment)

  end

  describe "validations" do

    it "should have assigned_app_id" do
      @assigned_environment1 = AssignedEnvironment.new
      @assigned_environment1.update_attributes({:environment_id => @env1.id, :role => @user1.roles.first})
      @assigned_environment1.should_not be_valid
    end

    it "should have env_id" do
      @assigned_environment1 = AssignedEnvironment.new
      @assigned_environment1.update_attributes({:assigned_app_id => @assigned_app1.id, :role => @user1.roles.first})
      @assigned_environment1.should_not be_valid
    end

    it "should have role" do
      @assigned_environment1 = AssignedEnvironment.new
      @assigned_environment1.update_attributes({:assigned_app_id => @assigned_app1.id, :environment_id => @env1.id})
      @assigned_environment1.should_not be_valid
    end

    it "should validate" do
      @assigned_environment1 = AssignedEnvironment.new
      @assigned_environment1.update_attributes({:assigned_app_id => @assigned_app1.id, :environment_id => @env1.id, :role => @user1.roles.first})
      @assigned_environment1.should be_valid
    end

  end

  describe "custom_functions" do

    it "should return correct app name" do
      @assigned_environment1 = AssignedEnvironment.new
      @assigned_environment1.update_attributes({:assigned_app_id => @assigned_app1.id, :environment_id => @env1.id, :role => @user1.roles.first})
      @assigned_environment1.app_name.should == @app1.name
    end

    it "should return correct app_id" do
      @assigned_environment1 = AssignedEnvironment.new
      @assigned_environment1.update_attributes({:assigned_app_id => @assigned_app1.id, :environment_id => @env1.id, :role => @user1.roles.first})
      @assigned_environment1.app_id.should == @app1.id
    end

    it "should return correct environment_name" do
      @assigned_environment1 = AssignedEnvironment.new
      @assigned_environment1.update_attributes({:assigned_app_id => @assigned_app1.id, :environment_id => @env1.id, :role => @user1.roles.first})
      @assigned_environment1.environment_name.should == @env1.name
    end

  end

  describe "associations" do

    it "should belong to" do
      @assigned_environment1 = AssignedEnvironment.new
      @assigned_environment1.update_attributes({:assigned_app_id => @assigned_app1.id, :environment_id => @env1.id, :role => @user1.roles.first})
      @assigned_environment1.should belong_to(:environment)
      @assigned_environment1.should belong_to(:assigned_app)
    end

  end
end
