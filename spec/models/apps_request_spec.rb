################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
require 'spec_helper'

describe AppsRequest do

  before(:each) do
    User.current_user = create(:user)
    @request1 = create(:request, :name => 'request1')
    @request2 = create(:request, :name => 'request2')
    @app1 = create(:app, :name => 'app1')
    @app2 = create(:app, :name => 'app2')
    @apps_request = create(:apps_request, :app => @app1, :request => @request1)
  end

  describe "validations" do

    it "should use factory" do
      @apps_request_2 = build(:apps_request, :app => @app1, :request => @request1)
      @apps_request_2.should_not be_valid
    end
  end

  describe "associations" do

    it "should belong to" do
      @apps_request.should belong_to(:app)
      @apps_request.should belong_to(:request)
    end

  end

end
