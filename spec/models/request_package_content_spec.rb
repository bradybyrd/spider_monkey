################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RequestPackageContent do
  before(:each) do
    @valid_attributes = {
    }
    @requestPackageContent = RequestPackageContent.create!(@valid_attributes)
  end

  it { @requestPackageContent.should belong_to(:request) }
  it { @requestPackageContent.should belong_to(:package_content) }
end