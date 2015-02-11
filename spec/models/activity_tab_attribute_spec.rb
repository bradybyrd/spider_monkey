################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ActivityTabAttribute do
  before(:each) do
    @valid_attributes = {
      :activity_tab_id => 1,
      :activity_attribute_id => 1
    }
    @activityTabAttribute = create(:activity_tab_attribute, @valid_attributes)
  end

  it { @activityTabAttribute.should belong_to(:activity_tab) }
  it { @activityTabAttribute.should belong_to(:activity_attribute) }
end
