################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require File.join(Rails.root, 'spec', 'spec_helper')

describe ActivityWidget do
  describe "#widget?" do
    it "is true" do
      ActivityWidget.new.should be_widget
    end
  end

  describe "#static?" do
    it "is false" do
      ActivityWidget.new.should_not be_static
    end
  end

  describe "#input_type" do
    it "is 'widget'" do
      ActivityWidget.new.input_type.should == 'widget'
    end
  end

  describe "#value_for" do
    it "is nil" do
      ActivityWidget.new.value_for(:something).should be_nil
    end
  end

  describe "#pretty_value_for" do
    it "is ''" do
      ActivityWidget.new.pretty_value_for("This unimportant string").should == ''
    end
  end
end
