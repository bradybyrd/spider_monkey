################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe SecurityAnswer do

  before(:each) do
    User.current_user = User.find_by_login("admin")
    @security_answer = SecurityAnswer.new
  end

  describe "associations" do
    it "belongs to" do
      @security_answer.should belong_to(:user)
    end
  end

  describe "validations" do
    it "validates presence of" do
      @security_answer.should validate_presence_of(:answer)
    end
  end
end