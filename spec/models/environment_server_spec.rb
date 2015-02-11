################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require File.dirname(__FILE__) + '/../spec_helper'

describe EnvironmentServer do
  before(:each) do
    @environment = create(:environment)
    @environment_server = EnvironmentServer.new
  end

  describe "associations" do
    it { @environment_server.should belong_to(:environment) }
    it { @environment_server.should belong_to(:server) }
    it { @environment_server.should belong_to(:server_aspect) }
  end

  describe "validations" do

    it "should validate presence of" do
      @environment_server.should validate_presence_of(:environment)
    end
    describe "for the server association" do
      it "is invalid when both the server and server aspect are blank" do
        @environment_server = build(:environment_server, environment: @environment, server: nil, server_aspect: nil )
        @environment_server.should_not be_valid
      end

      it "is invalid when both the server and server aspect are present" do
        @environment_server = build(:environment_server, environment: @environment, server: Server.new, server_aspect: ServerAspect.new )
        @environment_server.should_not be_valid
      end

      it "is valid when there is just a server" do
        @environment_server = build(:environment_server, environment: @environment, server: Server.new, server_aspect: nil )
        @environment_server.should be_valid
      end

      it "is valid when there is just an server aspect" do
        @environment_server = build(:environment_server, environment: @environment, server: nil, server_aspect: ServerAspect.new )
        @environment_server.should be_valid
      end
    end
  end
end

