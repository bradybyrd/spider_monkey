################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe ComponentProperty do

  before do
    @component_property = ComponentProperty.new
  end

  it { @component_property.should belong_to(:component) }
  it { @component_property.should belong_to(:property) }
  it { @component_property.should belong_to(:active_property)}

  describe "#insertion_point=" do
    it "should insert the component_property at the given position" do
      @component_property.should_receive(:insert_at).with(5)
      @component_property.insertion_point = 5
    end
  end

  describe "#insertion_point" do
    it "should return the position" do
      @component_property.position = 10
      @component_property.insertion_point.should == @component_property.position
    end
  end
end


