################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe AppsBusinessProcess do

  before do

    User.current_user = create(:user)

    @app1 = create(:app)
    @business_process1 = create(:business_process)

  end

  describe "associations" do

    it "should belong to" do
      @app_business_process1 = create(:apps_business_process, :app => @app1, :business_process => @business_process1)
      @app_business_process1.should be_valid
      @app_business_process1.should belong_to(:app)
      @app_business_process1.should belong_to(:business_process)
    end
  end

end
