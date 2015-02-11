################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EnvironmentRole do
  before(:each) do
    @user = create(:user, :admin => true)
    User.stub(:current_user).and_return(@user)
    @environment1 = create(:environment)
    @environment_role = create(:environment_role, :user => @user, :environment_id => @environment1.id, :role => @user.roles.first)

  end

  describe "validations" do
    it "should validate presence of" do
      @environment_role.should validate_presence_of(:user_id)
      @environment_role.should validate_presence_of(:environment_id)
      @environment_role.should validate_presence_of(:role)
    end
  end

  describe "associations" do
    it "should belong to" do
      @environment_role.should belong_to(:environment)
      @environment_role.should belong_to(:user)
    end
  end
end

