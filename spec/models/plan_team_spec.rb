################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PlanTeam do
  before(:each) do
    @plan_team = PlanTeam.new
    @valid_attributes = {
      :plan_id => 1,
      :team_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    @plan_team.update_attributes(@valid_attributes)
    @plan_team.should be_valid
  end

  it "should be invalid without a plan id" do
    @valid_attributes[:plan_id] = nil
    @plan_team.update_attributes(@valid_attributes)
    @plan_team.should_not be_valid
  end

  it "should be invalid without a team id" do
    @valid_attributes[:team_id] = nil
    @plan_team.update_attributes(@valid_attributes)
    @plan_team.should_not be_valid
  end
end
