################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe DevelopmentTeam do
  before(:each) do
    User.current_user = User.find_by_login("admin")
    @valid_attributes = {

    }
  end

  describe "associations" do

    it "should belong to" do
      @development_team1 = DevelopmentTeam.create!(@valid_attributes)
      @development_team1.should belong_to(:team)
      @development_team1.should belong_to(:app)

    end
  end
end

