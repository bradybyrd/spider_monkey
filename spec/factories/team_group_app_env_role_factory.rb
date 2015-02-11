FactoryGirl.define do
  factory :team_group_app_env_role do
    association :team_group, factory: :team_group
    association :role, factory: :role
    association :application_environment, factory: :application_environment
  end
end
