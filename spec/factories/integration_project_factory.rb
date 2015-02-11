FactoryGirl.define do
  factory :integration_project do
    project_server
    sequence(:name) { |n| "project_servers #{n}" }
    active true
  end
end
