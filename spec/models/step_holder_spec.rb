################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe StepHolder do
  before(:each) do
    @stepHolder = create(:step_holder)
  end

  describe "belongs to" do
    it { @stepHolder.should belong_to(:step) }
    it { @stepHolder.should belong_to(:request) }
  end

end
