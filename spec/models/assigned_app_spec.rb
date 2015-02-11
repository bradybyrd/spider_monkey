################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
require 'spec_helper'

describe AssignedApp do

  before(:each) do
    @user = create(:user, :admin => true)
    User.stub(:current_user).and_return(@user)
    @app1 = create(:app, :name => 'app1')
    @app2 = create(:app, :name => 'app2')
    @user1 = create(:user, :login => 'adeodhar')

  end

  describe "validations" do


    it "should have user_id" do
      @assigned_app = AssignedApp.new
      @assigned_app.update_attributes({:app_id => @app1.id});
      @assigned_app.should_not be_valid
    end

    it "should have app_id" do
      @assigned_app = AssignedApp.new
      @assigned_app.update_attributes({:user_id => User.current_user.id});
      @assigned_app.should_not be_valid
    end

    it "should have unique entry of a user per app" do
      #@assigned_app = AssignedApp.new
      @assigned_app1 = AssignedApp.create(:user_id => @user1.id, :app_id => @app1.id)
      @assigned_app1.should be_valid

      @assigned_app1 = AssignedApp.new
      @assigned_app1.update_attributes({:user_id => @user1.id, :app_id => @app1.id});
      @assigned_app1.should_not be_valid

      @assigned_app2 = AssignedApp.new
      @assigned_app2.update_attributes({:user_id => @user1.id, :app_id => @app2.id});
      @assigned_app2.should be_valid

    end

  end

  describe "associations" do

    it "should belong to" do
      @assigned_app1 = AssignedApp.create(:user_id => @user1.id, :app_id => @app1.id)
      @assigned_app1.should belong_to(:app)
      @assigned_app1.should belong_to(:user)
      @assigned_app1.should belong_to(:team)
    end

  end

end
