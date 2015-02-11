################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ActivityCreationAttribute do
  before(:each) do
    @activity_creation_attribute = ActivityCreationAttribute.new
  end
  describe "validations" do
    it { @activity_creation_attribute.should validate_presence_of(:activity_category_id) }
    it { @activity_creation_attribute.should validate_presence_of(:activity_attribute_id) }
  end
  describe "belong_to" do
    it { @activity_creation_attribute.should belong_to(:activity_category) }
    it { @activity_creation_attribute.should belong_to(:activity_attribute) }
  end
end
