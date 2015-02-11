################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe ServerLevelProperty do
  before(:each) do
    @server_level_property = ServerLevelProperty.new
  end

  describe "validations and associations" do
    it { @server_level_property.should belong_to(:server_level) }
    it { @server_level_property.should belong_to(:property) }

    it { @server_level_property.should validate_presence_of(:server_level) }
    it { @server_level_property.should validate_presence_of(:property) }
  end
end

