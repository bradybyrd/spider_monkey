################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe ServerAspectGroup do
  before do
    @server_aspect_group = ServerAspectGroup.create(:name => "SAG001")
  end

  describe "validations" do
    it { @server_aspect_group.should validate_presence_of(:name) }
    it { @server_aspect_group.should validate_uniqueness_of(:name) }
  end

  describe "associations" do
    it "should have and belong to many" do
      @server_aspect_group.should have_and_belong_to_many(:server_aspects)
    end
  end

  describe "normalizations" do
    it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
  end
end

