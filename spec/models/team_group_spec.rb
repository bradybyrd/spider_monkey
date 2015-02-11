################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TeamGroup do
  before(:each) do
    @team_group1 = TeamGroup.new
  end

  describe "associations" do
    it "should belong to" do
      @team_group1.should belong_to(:group)
      @team_group1.should belong_to(:team)
    end
  end

end
