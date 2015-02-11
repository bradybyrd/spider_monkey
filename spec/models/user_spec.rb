################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################
require 'spec_helper'


describe User do

  describe 'validations' do
    before(:each) do
      @user = User.new
    end

    it { @user.should validate_presence_of(:first_name) }
    it { @user.should validate_presence_of(:last_name) }
    it { @user.should validate_presence_of(:password) }

    it 'does not allow update of inactive user', custom_roles: true do
      user = build(:user, active: false)
      user.update_attributes(first_name: 'test')
      expect(user.errors_on(:base)).to include I18n.t('user.edit_error')
    end
  end

  describe 'associations' do
    it { should have_many(:user_groups) }
    it { should have_many(:groups).through(:user_groups) }
    it { should have_many(:apps_from_team).through(:teams) }
  end

  describe '#ensure_default_group' do
    it 'assigns default group to user if no group was assigned' do
      default_group = create(:group, name: '[default]', position: 1)
      user = create(:user, group_ids: [])
      expect(user.groups).to include(default_group)
    end
  end

  describe '#in_root_group?' do
    it 'returns true' do
      group = create(:group, name: 'Have Heart', root: true)
      user = create(:user, group_ids: [group.id])
      expect(user.in_root_group?).to be(true)
    end

    it 'returns false' do
      group = create(:group, name: 'Ember Spirit', root: false)
      user = create(:user, group_ids: [group.id])
      expect(user.in_root_group?).to be(false)
    end
  end

  describe 'old_style_validations' do
    describe 'login' do
      describe 'non nil' do
        let(:user) { build(:user, login: nil) }
        it do
          expect(user.valid?).to be_falsey
          expect(user.errors[:login].size).to be >= 1
        end
      end
      describe '>= 3' do
        let(:user) { build(:user, login: 'ab') }
        it do
          expect(user.valid?).to be_falsey
          expect(user.errors[:login].size).to be >= 1
        end
      end
      describe '<= 100' do
        let(:user) { build(:user, login: 'a'*105) }
        it do
          expect(user.valid?).to be_falsey
          expect(user.errors[:login].size).to be >= 1
        end
      end
    end

    describe 'email' do
      describe '>= 3' do
        let(:user) { build(:user, email: nil) }
        it do
          expect(user.valid?).to be_falsey
          expect(user.errors[:email].size).to be >= 1
        end
      end
      describe '<= 100' do
        let(:user) { build(:user, email: 'a'*105) }
        it do
          expect(user.valid?).to be_falsey
          expect(user.errors[:email].size).to be >= 1
        end
      end
    end

    describe 'max allocation' do
      describe '>= 0' do
        let(:user) { build(:user, max_allocation: -5) }
        it do
          expect(user.valid?).to be_falsey
          expect(user.errors[:max_allocation].size).to be == 1
        end
      end
      describe '<= 100' do
        let(:user) { build(:user, max_allocation: 105) }
        it do
          expect(user.valid?).to be_falsey
          expect(user.errors[:max_allocation].size).to be == 1
        end
      end
    end

    describe 'employment type' do
      describe 'listed type' do
        let(:user) { build(:user, employment_type: 'wrong_type') }
        it do
          expect(user.valid?).to be_falsey
          expect(user.errors[:employment_type].size).to be == 1
        end
      end
    end

    describe 'location' do
      before(:each) {
        list = create(:list, name: 'Locations')
        list_item = create(:list_item, list: list, value_text: 'New York')
      }
      context 'when invalid location' do
        let(:user) { build(:user, location: 'Boston') }
        it do
          expect(user.valid?).to be_falsey
          expect(user.errors[:location].size).to be == 1
        end
      end
      context 'when valid location' do
        subject { build(:user, location: 'New York') }
        it { should be_valid }
      end
    end

  end

  describe 'convenience accessors' do
    it "should return ':last_name, :first_name' when calling :name_for_index" do
      User.new(first_name: 'bob', last_name: 'smith').name_for_index.should == 'smith, bob'
    end

    describe '#location_name' do
      it 'returns an upcase version of the location string' do
        User.new(location: 'usem').location_name.should == 'USEM'
      end

      it "is '' when there is no location" do
        User.new.location_name.should == ''
      end
    end

    describe 'employment_type_name' do
      it 'should return the titleized employment type' do
        User.new(employment_type: 'contractor').employment_type_name.should == 'Contractor'
      end
    end

    describe '#workstream_names' do
      let(:user) { build(:user) }
      let(:workstreams) { [double('workstream', name: 'ws1'), double('workstream2', name: 'ws2')] }
      it "should return the names of the user's workstreams, joined by commas" do
        user.stub(:workstreams).and_return(workstreams)
        expect(user.workstream_names).to eq('ws1, ws2')
      end
    end

    describe '#role_names' do
      it 'returns a titleized version of the users roles' do
        user = User.new
        user.roles = [build(:role, name: 'This is'), build(:role, name: 'My first time')]
        user.role_names.should == 'This Is, My First Time'
      end
    end

  end

  # FIXME: We should convert constants to class accessors, here is just one of many converted
  describe 'constants and class accessors: ' do
    it 'locations should return a sorted array from the Locations list' do
      list = create(:list, name: 'Locations')
      list_item = create(:list_item, list: list, value_text: 'New York')
      list_item = create(:list_item, list: list, value_text: 'Boston')
      User.locations.should == ['Boston', 'New York']
    end
  end

  describe '#manages?' do
    before do
      @user = User.new
      @group = Group.new
    end

    describe 'when given a group' do
      before do
        @group = Group.new
      end

      it 'is true when the user is an admin' do
        @user = stub_model User, root?: true
        @user.manages?(@group).should be_truthy
      end

      it "is true when the group is in the user's managed groups" do
        @user.managed_groups << @group
        @user.manages?(@group).should be_truthy
      end

      it 'is false otherwise' do
        @user.manages?(@group).should be_falsey
      end
    end
  end

  describe '#activate!' do
    it 'should set active to true' do
      @user = create_user(active: false)
      @user.active?.should be_falsey
      @user.activate!
      @user.active?.should be_truthy
    end
  end

  describe '#deactivate!' do
    it 'should set active to false' do
      @user = create_user(active: true)
      @user.active?.should be_truthy
      @user.deactivate!
      @user.active?.should be_falsey
    end
  end

  describe 'named scopes' do
    describe '#root_users' do
      before do
        @user1 = create_user(:root)
        @user2 = create_user(:non_root)
      end
      it 'should return all users who are root' do
        User.root_users.should include(@user1)
        User.root_users.should_not include(@user2)
      end

      it 'should be filterable' do
        User.filtered({root: 'true'}).should include(@user1)
        User.filtered({root: 'true'}).should_not include(@user2)
      end
    end

    describe '#active' do
      before do
        @user1 = create_user(active: true)
        @user2 = create_user(active: false)
      end

      subject { User.active }
      it { should include(@user1) }
      it { should_not include(@user2) }

      context 'filtered(active)' do
        subject { User.filtered(active: 'true') }
        it { should include(@user1) }
        it { should_not include(@user2) }
      end

      context 'filtered(active=false)' do
        subject { User.filtered(active: 'false') }
        it { should_not include(@user1) }
        it { should_not include(@user2) }
      end

    end

    describe '#inactive' do

      before do
        @user1 = create_user(active: false)
        @user2 = create_user(active: true)
      end

      it 'should return all users who are inactive' do
        User.inactive.should include(@user1)
        User.inactive.should_not include(@user2)
      end

      it 'should be filterable' do
        User.filtered({inactive: 'true'}).should include(@user1)
        User.filtered({inactive: 'true'}).should_not include(@user2)
        User.filtered({inactive: 'false'}).should_not include(@user1)
        User.filtered({inactive: 'false'}).should include(@user2)
      end
    end

    # TODO: Flesh out this scenario to include more likely keyword combinations
    describe '#keyword' do

      before do
        @user1 = create_user(first_name: 'Samz', last_name: 'Sample', login: 'ssmple')
        @user2 = create_user(first_name: 'Jane', last_name: 'Rogers', login: 'jrgers')
      end

      it 'should return all users who match last name' do
        User.by_keyword('Sample').should include(@user1)
        User.by_keyword('Sample').should_not include(@user2)
      end

      it 'should return all users who match first name' do
        User.by_keyword('Samz').should include(@user1)
        User.by_keyword('Samz').should_not include(@user2)
      end

      it 'should return all users who match full name' do
        User.by_keyword('Samz Sample').should include(@user1)
        User.by_keyword('Samz Sample').should_not include(@user2)
      end

      it 'should return all users who match reverse full name' do
        User.by_keyword('Sample Samz').should include(@user1)
        User.by_keyword('Sample Samz').should_not include(@user2)
      end

      it 'should return all users who match login' do
        User.by_keyword('ssmple').should include(@user1)
        User.by_keyword('ssmple').should_not include(@user2)
      end

      it 'should be filterable' do
        User.filtered({keyword: 'Sample'}).should include(@user1)
        User.filtered({keyword: 'Sample'}).should_not include(@user2)
        User.filtered({keyword: 'Samz Sample'}).should include(@user1)
        User.filtered({keyword: 'Samz Sample'}).should_not include(@user2)
        User.filtered({keyword: 'Sample Samz'}).should include(@user1)
        User.filtered({keyword: 'Sample Samz'}).should_not include(@user2)
        User.filtered({keyword: 'ssmple'}).should include(@user1)
        User.filtered({keyword: 'ssmple'}).should_not include(@user2)
      end
    end

    # TODO: Fill out the rest of the named scopes

  end

  describe 'api_key authentication' do
    let(:root)          { create :user, :root }
    let(:ordinary_user) { create :user, :non_root }

    it 'should allow admins access' do
      User.api_key_authentication(root.api_key).should == root
    end

    it 'should NOT allow admins access by legacy password_salt' do
      User.api_key_authentication(root.password_salt).should be_nil
    end

    it 'should allow not allow non-admins access' do
      User.api_key_authentication(ordinary_user.api_key).should be_nil
    end

    it 'should not allow non-admins access' do
      User.api_key_authentication(ordinary_user.api_key).should be_nil
    end

    it 'should not allow inactive root users access' do
      root.update_attribute(:active, false)
      User.api_key_authentication(root.api_key).should be_nil
    end

    it 'should not allow inactive ordinary users access' do
      ordinary_user.update_attribute(:active, false)
      User.api_key_authentication(ordinary_user.api_key).should be_nil
    end

    it 'should provide an api key for admins' do
      root.api_key.should_not be_nil
    end

    it 'should NOT provide an api key for ordinary users' do
      ordinary_user.api_key.should be_nil
    end

    it 'should NOT provide an api key for inactive admin or ordinary users' do
      root.update_attribute(:active, false)
      root.api_key.should be_nil
      ordinary_user.update_attribute(:active, false)
      ordinary_user.api_key.should be_nil
    end

    it 'should be 40 character long' do
      root.api_key.length.should == 40
    end
  end

  describe 'change password' do
    before(:each) { @user = create(:user, password: 'old_pass') }
    subject { @user }
    specify { @user.valid_password?('old_pass').should be_truthy }
    context 'when confirmation != password' do
      before(:each) { @result = @user.change_password!('new_pass', 'new_error_pass', 'old_pass') }
      it do
        expect(@user.valid?).to be_falsey
        expect(@user.errors[:password].size).to be >= 1
      end
      specify { @user.valid_password?('old_pass').should be_truthy }
      specify { @result.should be_falsey }
    end
    context 'when old password != password' do
      before(:each) { @result = @user.change_password!('new_pass', 'new_pass', 'old_pass_error') }
      it do
        expect(@user.valid?).to be_falsey
        expect(@user.errors[:base].size).to be >= 1
      end
      specify { @user.valid_password?('old_pass').should be_truthy }
      specify { @result.should be_falsey }
    end
    context 'when old password is nil' do
      before(:each) { @result = @user.change_password!('new_pass', 'new_error_pass', nil) }
      it do
        expect(@user.valid?).to be_falsey
        expect(@user.errors[:password].size).to be >= 1
      end
      specify { @user.valid_password?('old_pass').should be_truthy }
      specify { @result.should be_falsey }
    end
    context 'when password is correct' do
      before(:each) do
        @user.stub(:notification_failed).and_return(false)
        @result = @user.change_password!('new_pass', 'new_pass', 'old_pass')
      end
      specify { @user.valid_password?('new_pass').should be_truthy }
      specify { @result.should be_truthy }
    end

  end

  describe '#set_reset_password_token' do
    context 'init with login' do
      before(:each) { @user = create(:user) }
      specify { @user.reset_password_token.should == @user.login }
    end

    context 'init with date-time stamp and object id' do
      before(:all) do
        @now = DateTime.now
        DateTime.stub(:now).and_return @now
        DateTime.should_receive(:now).and_return @now

        @user = create(:user, login: nil, system_user: false)
        @expected_token = @now.strftime('%F %T.%L%:z') + ' ' + @user.object_id.to_s
      end
      specify { @user.reset_password_token.should_not == @user.login }
      specify { @user.reset_password_token.should == @expected_token }
    end
  end

  describe '#filtered' do

    before(:all) do
      User.delete_all
      @user1 = create_user(active: true)
      @user2 = create_user(active: false)
      @user3 = create_user(active: true, root: true, first_name: 'John', last_name: 'Smith', login: 'jsmith_adm', email: 'jsmith@dev.org')
      @active = [@user1, @user3]
      @inactive = [@user2]
    end

    after(:all) do
      User.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter by all fields' do
        result = described_class.filtered(root: 'true', keyword: 'jsmith_adm', first_name: 'John', last_name: 'Smith', email: 'jsmith@dev.org')
        result.should match_array([@user3])
      end
    end
  end

  describe '#timeout_in' do
    let(:user) { create(:user) }

    it 'sets session timeout using default Devise configuration' do
      GlobalSettings[:session_timeout] = nil
      user.timeout_in.should eq 30.minutes
    end

    it 'sets session timeout using global settings' do
      GlobalSettings[:session_timeout] = 1.hour
      user.timeout_in.should eq 1.hour
    end
  end

  describe '#email?' do
    let(:user) { create_user }

    it 'returns true if user has email' do
      expect(user.send(:email?)).to be_truthy
    end

    it 'returns false if user does not have email' do
      user.email = nil
      expect(user.send(:email?)).to be_falsey
    end
  end

  describe '#is_reset_password?' do
    let(:user) { create_user }

    it "returns true if user doesn't reset password" do
      expect(user.send(:is_reset_password?)).to be_falsey
    end

    it 'returns false if user reset password' do
      user.reset_password!
      expect(user.send(:is_reset_password?)).to be_truthy
    end

    it 'returns false if user does not have password' do
      user.password = nil
      expect(user.send(:is_reset_password?)).to be_falsey
    end
  end

  describe '#send_welcome_email' do
    let(:admin) { create_user :root }
    let(:user)  { create_user :non_root }

    before(:each) do
      User.delete_all
      admin
      user
      Notifier.stub(:delay).and_return(double(Notifier).as_null_object)
    end

    it 'calls send_welcome_email_for_user' do
      user.should_receive(:send_welcome_email_for_user)
      user.send(:send_welcome_email)
    end

    it 'does not call send_welcome_email_for_user' do
      user.stub(:email_exists?).and_return(false)
      user.should_not_receive(:send_welcome_email_for_user)
      user.send(:send_welcome_email)
    end

    it 'calls send_welcome_email_for_admin' do
      GlobalSettings.stub(:default_authentication_enabled?).and_return(false)
      admin.should_receive(:send_welcome_email_for_admin)
      admin.send(:send_welcome_email)
    end
  end

  describe '#admin?' do
    context 'when user not in root group' do
      it 'returns false' do
        group = create(:group, root: false)
        user = create(:user, groups: [group])

        expect(user).not_to be_admin
      end
    end

    context 'when user in root group' do
      it 'returns true' do
        group = create(:group, root: true)
        user = create(:user, groups: [group])

        expect(user).to be_admin
      end
    end
  end

  describe 'default team' do
    it 'does not add user into a team by default' do
      user = create :user

      expect(user.teams).to be_empty
    end
  end

  describe 'removing last user from group with name "Root"'do
    it 'is not possible' do
      user = create :user, :non_root, login: 'Logan'
      user.stub(:new_password_validation)
      group = create :group, name: Group::ROOT_NAME, root: true, resources: [user]

      expect(group.resources).to eq [user]
      expect(user.reload.groups.size).to eq(2)
      user.groups = []

      expect(group.reload.resources).to eq [user]
      expect(user.reload.groups).to eq [group]
    end

    it 'makes user invalid' do
      user = create :user, :non_root, login: 'Logan'
      user.stub(:new_password_validation)
      create :group, name: Group::ROOT_NAME, root: true, resources: [user]

      expect(user.reload.groups.size).to eq(2)
      user.groups = []

      expect(user).not_to be_valid
    end
  end

  describe 'removing inactive group' do
    it 'is possible' do
      group_deactivated = create(:group)
      group_active = create(:group)
      user = create(:user, groups: [group_active, group_deactivated])
      group_deactivated.deactivate!

      user.groups = [group_active]
      user.save

      expect(user.groups.size).to eq(1)
    end
  end

  describe '#environments_visible_to_user' do
    context 'for user with assigned app from team' do
      it 'returns only environments assigned to application which user has access through team' do
        user        = create(:user, :non_root, login: 'Mr. Doe')
        environment = create(:environment, name: 'Almighty')
        group       = create(:group)
        team        = create(:team, groups: [group])
        app         = create(:app, environments: [environment], teams:[team])
        create(:environment, name: 'Environment not assigned to app')

        # verify user cannot see this environment
        expect(app.environments_visible_to_user(user)).not_to include [environment]

        # now assign user to group with the application
        user.groups = [group]
        user.save

        # verify user can see this environment
        expect(user.accessible_environments).to eq [environment]
      end
    end
  end

  describe '#active_apps' do
    it 'returns apps from active groups and teams' do
      user = create(:user)
      active_team = create(:team_with_apps_and_groups)
      inactive_team = create(:team_with_apps_and_groups, active: false)
      team_with_inactive_group = create(:team_with_apps_and_groups)
      team_with_inactive_group.groups[0].deactivate!
      [active_team, inactive_team, team_with_inactive_group].each do |team|
        team.groups[0].users = [user]
      end

      expect(user.active_apps).to match_array(active_team.apps.uniq)
    end
  end

  describe '#update_assigned_apps' do
    it 'assigns active apps to user' do
      user = create(:user)
      app = create(:app)
      apps = App.where(id: app.id)
      user.stub(:active_apps).and_return(apps)

      user.update_assigned_apps

      expect(user.reload.apps).to match_array(apps)
    end

    it 'does not create duplicates' do
      user = create(:user)
      app = create(:app)
      apps = App.where(id: app.id)
      user.stub(:active_apps).and_return(apps)
      create(:assigned_app, user: user, app: app, team: nil)

      user.update_assigned_apps

      expect(user.reload.apps).to match_array(apps)
    end

    it 'removes app assignment if user has no apps through teams' do
      app = create(:app)
      user = create(:user, apps: [app])

      expect(user.apps).not_to be_empty

      user.update_assigned_apps

      expect(user.reload.apps).to be_empty
    end

    it 'removes app assignment if app is no longer available to user' do
      user = create(:user, apps: [create(:app)])
      new_app = create(:app)
      new_apps = App.where(id: new_app.id)
      allow(user).to receive(:active_apps).and_return(new_apps)

      expect(user.apps).not_to be_empty

      user.update_assigned_apps

      expect(user.reload.apps).to match_array(new_apps)
    end
  end

  protected

  def create_user(options = nil)
    create(:user, options)
  end

end

