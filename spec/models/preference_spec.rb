################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe Preference do

  describe 'associations and validations' do
    before(:each) do
      @preference = Preference.new
    end
    it { expect(@preference).to belong_to(:user) }
    it { expect(@preference).to validate_presence_of(:text) }
    it { expect(@preference).to validate_presence_of(:preference_type) }
  end

  describe 'attribute normalizations' do
    it { expect(normalize_attribute(:text).from('  Hello  ').to('Hello')) }
  end

  describe 'named scopes' do

    describe '#active' do
      it 'should return all preferences in an active state' do
        preference = create(:preference, active: true)
        expect(Preference.active).to include(preference)
      end

      it 'should not return preferences in an inactive state' do
        preference = create(:preference, active: false)
        expect(Preference.active).to_not include(preference)
      end
    end
  end

  describe 'request list preferences' do

    before(:each) do
      @preference = Preference.new
    end

    it 'should define a valid set of request list preference names' do
      expect(Preference::Requestlist).to eq([
        'request_name_td',
        'request_owner_td',
        'request_requestor_td',
        'request_business_process_td',
        'request_release_td',
        'request_app_td',
        'request_env_td',
        'request_deployment_window_td',
        'request_scheduled_td',
        'request_duration_td',
        'request_due_td',
        'request_steps_td',
        'request_created_td',
        'request_participants_td',
        'request_project_td',
        'request_package_contents_td',
        'request_team_td',
        'request_started_at_td'
      ])
    end

    it 'should automatically load correct Request preferences for a user on first request' do
      @user = create(:user)
      expect(Preference.find_by_user_id(@user.id)).to be_nil
      Preference.request_list_for(@user)
      expect(Preference.where(user_id: @user.id).count).to eq(Preference::Requestlist.length)
    end

    # this capability was commented out pending a more comprehensive review of this system, see Review 8632.
    # it "should automatically purge old or invalid Request preferences for a user" do
      # @user = create(:user)
      # Preference.find_by_user_id(@user.id).should be_nil
      # @new_preference = create(:preference, :user_id => @user.id, :preference_type => 'Request', :string => 'Request', :text => 'INVALID VALUE')
      # Preference.find(:all, :conditions => { :user_id => @user.id }).count.should == 1
      # Preference.request_list_for(@user)
      # Preference.find(:all, :conditions => { :user_id => @user.id }).count.should == Preference::Requestlist.length
    # end
  end
end

