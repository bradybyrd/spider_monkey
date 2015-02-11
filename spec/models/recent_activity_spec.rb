################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe RecentActivity do
  before do
    User.current_user = User.find_by_login("admin")
    @recent_activity1 = RecentActivity.new
  end

  describe "validations" do

    it "validates presence of" do
      @recent_activity1.should validate_presence_of(:actor)
      @recent_activity1.should validate_presence_of(:object)
      @recent_activity1.should validate_presence_of(:verb)
    end

  end

  describe "associations" do
    it "should belong to" do
      @recent_activity1.should belong_to(:actor)
      @recent_activity1.should belong_to(:object)
      @recent_activity1.should belong_to(:indirect_object)
    end
  end

end
