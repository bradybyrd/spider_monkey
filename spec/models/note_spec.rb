################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require File.dirname(__FILE__) + '/../spec_helper'

describe Note do
  before(:each) do
    @note = create(:note, :content => "\nScript content")
  end
  describe 'validations' do
    it { @note.should validate_presence_of(:user) }
    it { @note.should validate_presence_of(:content) }
  end
  describe 'belong_to' do
    it { @note.should belong_to(:user) }
  end

  describe 'definitions' do
    describe 'holder'
      it 'holder should return user for user' do
        holder = create(:user)
        @note.holder_type_id = holder.id
        @note.holder_type = 'User'
        @note.save!
        @note.reload
        @note.holder_type.should == 'User'
        @note.holder.should == holder
      end
      it 'holder should return group for group' do
        holder = create(:group)
        @note.holder_type_id = holder.id
        @note.holder_type = 'Group'
        @note.save!
        @note.reload
        @note.holder_type.should == 'Group'
        @note.holder.should == holder
      end
  end
end
