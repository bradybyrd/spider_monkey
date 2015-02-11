################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe ServerAspect do
  before(:each) do
    @server_aspect = ServerAspect.new
  end

  describe "validations" do
    it { @server_aspect.should validate_presence_of(:name) }
  end

  describe "attribute normalizations" do
    it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
  end

  describe "associations" do
    it "should belong to" do
      @server_aspect.should belong_to(:parent)
      @server_aspect.should belong_to(:server_level)
    end

    it "should have many" do
      @server_aspect.should have_many(:server_aspects)
      @server_aspect.should have_many(:property_values)
      @server_aspect.should have_many(:properties_with_values)
      @server_aspect.should have_many(:current_property_values)
      @server_aspect.should have_many(:deleted_property_values)
      @server_aspect.should have_many(:environment_servers)
      @server_aspect.should have_many(:environments)
    end

    it "should have and belong to many" do
      @server_aspect.should have_and_belong_to_many(:installed_components)
      @server_aspect.should have_and_belong_to_many(:groups)
    end
  end

end
