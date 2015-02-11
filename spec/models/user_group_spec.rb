################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserGroup do
  before(:each) do
    @user_group1 = UserGroup.new
  end

  describe 'associations' do
    it 'should belong to' do
      @user_group1.should belong_to(:user)
      @user_group1.should belong_to(:group)
    end
  end
end

