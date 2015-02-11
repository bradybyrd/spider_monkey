################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe PackageProperty do

  before do
    @package_property = PackageProperty.new
  end

  it { @package_property.should belong_to(:package) }
  it { @package_property.should belong_to(:property) }
  it { @package_property.should belong_to(:active_property)}

  describe "#insertion_point=" do
    it "should insert the package_property at the given position" do
      @package_property.should_receive(:insert_at).with(5)
      @package_property.insertion_point = 5
    end
  end

  describe "#insertion_point" do
    it "should return the position" do
      @package_property.position = 10
      @package_property.insertion_point.should == @package_property.position
    end
  end
end


