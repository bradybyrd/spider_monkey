require 'spec_helper'

describe UserQuery do
  before { User.delete_all }

  describe '#users_with_access_to_apps' do
    context 'for non root user with assigned app' do
      it 'returns users that have access to application' do
        create :user, :non_root
        user = create :user, :non_root
        app = create_app_assigned_to_user(user)
        app_ids = app.id

        expect(user.query_object.users_with_access_to_apps(app_ids)).to eq [user]
      end

      it 'returns an empty array for non assigned application' do
        user = create :user, :non_root
        app = create_app_assigned_to_user(user)

        expect(user.query_object.users_with_access_to_apps(nil)).to be_empty
      end

      context 'with ignore_access option' do
        it 'returns all user' do
          user = create :user, :non_root
          app = create_app_assigned_to_user(user)
          app_ids = app.id

          actual_user_ids = user.query_object.users_with_access_to_apps(app_ids, ignore_access: true)
          expect(actual_user_ids).to eq User.all
        end
      end

      context 'with root user having no assigned app' do
        it 'returns users having access to application environment and root users' do
          user = create :user, :non_root
          root_user = create :user, :root
          app = create_app_assigned_to_user(user)
          app_ids = app.id

          actual_users = user.query_object.users_with_access_to_apps(app_ids)
          expect(actual_users).to match_array [root_user,  user]
        end
      end
    end
  end

  describe '#users_with_access_to_apps_and_environment' do
    context 'for non root user with assigned app' do
      it 'returns users that have access to application environment' do
        create :user, :non_root
        user = create :user, :non_root
        app, environment = create_app_and_environment_assigned_to_user(user)
        app_ids = [app.id]

        expect(user.query_object.users_with_access_to_apps_and_environment(app_ids, environment.id)).to eq [user]
      end

      it 'returns an empty array for non assigned environment' do
        user = create :user, :non_root
        app, environment = create_app_and_environment_assigned_to_user(user)
        app_ids = [app.id]

        expect(user.reload.environments).to eq [environment]
        expect(user.query_object.users_with_access_to_apps_and_environment(app_ids, nil)).to be_empty
      end

      it 'returns an empty array for non assigned application' do
        user = create :user, :non_root
        app, environment = create_app_and_environment_assigned_to_user(user)

        expect(user.reload.environments).to eq [environment]
        expect(user.query_object.users_with_access_to_apps_and_environment(nil, environment)).to be_empty
      end

      context 'with ignore_access option' do
        it 'returns all user' do
          user = create :user, :non_root
          app, environment = create_app_and_environment_assigned_to_user(user)
          app_ids = [app.id]

          actual_user_ids = user.query_object.users_with_access_to_apps_and_environment(app_ids, environment.id, ignore_access: true)
          expect(actual_user_ids).to eq User.all
        end
      end

      context 'with root user having no assigned app' do
        it 'returns users having access to application environment and root users' do
          user = create :user, :non_root
          root_user = create :user, :root
          app, environment = create_app_and_environment_assigned_to_user(user)
          app_ids = [app.id]

          actual_users = user.query_object.users_with_access_to_apps_and_environment(app_ids, environment.id)
          expect(actual_users).to match_array [root_user,  user]
        end
      end
    end
  end

  def create_app_assigned_to_user(user)
    group = user.groups.last
    app = create :app
    app.users = [user]
    create :team, groups: [group], apps: [app]

    app
  end


  def create_app_and_environment_assigned_to_user(user)
    group = user.groups.last
    environment = create :environment
    app = create :app, environments: [environment]
    app.users = [user]
    create :team, groups: [group], apps: [app]

    [app, environment]
  end
end