################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ActivityNote do
  before(:each) do
    @valid_attributes = {
        activity_id: 1,
        user_id: 1,
        contents: 'Contents'
    }
    @invalid_attributes = {}
    @activityNote =  ActivityNote.create!(@valid_attributes)
  end

  it { @activityNote.should belong_to(:user) }
  it { @activityNote.should belong_to(:activity) }


  describe 'validations' do
    describe 'validates_presence_of :user_id, :activity_id, :contents ' do
      it 'should validate presence of input_type with incorrect value' do
        activityNote = ActivityNote.create(@invalid_attributes)
        expect(activityNote).to_not be_valid
        expect(activityNote.errors[:activity_id].size).to eq(1)
        expect(activityNote.errors[:activity_id].size).to eq(1)
        expect(activityNote.errors[:contents].size).to eq(1)
      end

      it 'should validate presence of input_type with correct value' do
        activityNote = ActivityNote.create!(@valid_attributes)
        expect(activityNote).to be_valid
      end
    end
  end
  it 'delegates user_name to user' do
    user = create(:user)
    @activityNote.update_attributes(user_id: user.id)
    @activityNote.save!
    expect(@activityNote.user_name).to eq(user.name)
  end
end
