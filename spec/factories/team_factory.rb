FactoryGirl.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }

    factory :team_with_apps_and_groups, parent: :team do |team|
      apps {[FactoryGirl.create(:app)]}
      groups {[FactoryGirl.create(:group)]}

      before(:create) do |t, evaluator|
        t.apps << evaluator.apps
        t.groups << evaluator.groups
      end
    end

    factory :team_with_apps_and_groups_env_roles, parent: :team do |team|
      apps {[FactoryGirl.create(:app)]}
      ignore do
        groups_config {[{
           group: FactoryGirl.create(:group),
           app_env_roles: [{
            app: apps.first,
            env: FactoryGirl.create(:environment),
            role: FactoryGirl.create(:role),
            component: false
           }]
        }]}
      end

      before(:create) do |t, evaluator|
        t.apps << evaluator.apps
        t.groups << evaluator.groups_config.map{|hash| hash[:group]}
      end

      after(:create) do |t, evaluator|
        evaluator.groups_config.each do |hash|
          group = hash[:group]
          team_group = t.team_groups.where("group_id = ?", group.id).first
          hash[:app_env_roles].each do |app_env_role_hash|
            app = app_env_role_hash[:app].is_a?(Fixnum)? App.find(app_env_role_hash[:app]) : app_env_role_hash[:app]
            env_id = app_env_role_hash[:env].is_a?(Fixnum)? app_env_role_hash[:env] : app_env_role_hash[:env].id
            app_env = app.application_environments.where("environment_id = ?", env_id).first
            role = app_env_role_hash[:role].is_a?(Fixnum)? Role.find(app_env_role_hash[:role]) : app_env_role_hash[:role]
            tgaer = FactoryGirl.create(:team_group_app_env_role,
              team_group: team_group,
              application_environment: app_env,
              role: role
            )

            if app_env_role_hash[:component]
              app_component = app.application_components.where(component_id: app_env_role_hash[:component].id).first
              create(:installed_component, application_component: app_component, application_environment: app_env)
            end
          end
        end
      end
    end

    factory :default_team do
      id 0
    end
  end
end

