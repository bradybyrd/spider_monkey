require 'spec_helper'
require 'rake'

describe 'Smartrelease fixtures load' do
  before(:all) do
    Rake.application.rake_require 'tasks/app_fixtures'
    Rake::Task.define_task(:environment)
    Rake.application.invoke_task('app:fixtures:clean_install')
  end

  describe Group do
    describe 'Site Administrator' do
      it 'is created' do
        expect(Group.find_by_name('Site Administrator')).to be_present
      end

      it 'has "Site Administrator" Role assignment' do
        site_administrator_role_id = 1
        group = Group.find_by_name('Site Administrator')
        site_administrator_role_assignment = GroupRole.find_by_role_id(site_administrator_role_id)

        expect(group.group_roles).to include site_administrator_role_assignment
      end
    end

    describe 'Root' do
      it 'is created' do
        expect(Group.find_by_name('Root')).to be_present
      end

      it 'is root' do
        expect(Group.find_by_name('Root')).to be_root
      end

      it 'has no Role assignments' do
        group_roles = Group.find_by_name('Root').group_roles

        expect(group_roles).to be_empty
      end

      it 'includes "admin" user' do
        group = Group.find_by_name('Root')
        admin_user = User.find_by_login('admin')

        expect(group.users.size).to eq(1)
        expect(group.users).to include admin_user
      end
    end

    describe '[default]' do
      it 'is created' do
        expect(Group.find_by_name('[default]')).to be_present
      end

      it 'is default' do
        expect(Group.find_by_name('[default]')).to be_default
      end

      it 'has "User" Role assignment' do
        user_role_id = 5
        group = Group.find_by_name('[default]')
        user_role_assignment = GroupRole.find_by_role_id(user_role_id)

        expect(group.group_roles).to include user_role_assignment
      end
    end
  end

  describe User do
    it 'creates "admin"' do
      expect(User.find_by_login('admin')).to be_present
    end
  end

  describe Team do
    describe '[default]' do
      it 'is created' do
        expect(Team.find_by_name('[default]')).to be_present
      end

      it 'is default' do
        expect(Team.find_by_name('[default]')).to be_default
      end

      it 'includes "[default]" App' do
        team_apps = Team.find_by_name('[default]').apps
        default_app = App.find_by_name('[default]')

        expect(team_apps).to include default_app
      end

      it 'includes "[default]" Group' do
        team_groups = Team.find_by_name('[default]').groups
        default_group = Group.find_by_name('[default]')

        expect(team_groups).to include default_group
      end
    end
  end

  describe App do
    describe '[default]' do
      it 'is created' do
        expect(App.find_by_name('[default]')).to be_present
      end

      it 'is default' do
        expect(App.find_by_name('[default]')).to be_default
      end

      it 'includes "[default]" Environment' do
        app_environments = App.find_by_name('[default]').environments
        default_environment = Environment.find_by_name('[default]')

        expect(app_environments).to include default_environment
      end
    end
  end

end
