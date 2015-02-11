FactoryGirl.define do
  factory :installed_component do
    association :application_component
    association :application_environment
  end
end
