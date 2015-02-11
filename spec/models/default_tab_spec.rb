################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe DefaultTab do
  before do
    User.current_user = User.find_by_login("admin")
  end

  describe "associations" do
    it "should belong to" do
      @default_tab1 = DefaultTab.create()
      @default_tab1.should be_valid
      @default_tab1.should belong_to(:user)
    end
  end
end
