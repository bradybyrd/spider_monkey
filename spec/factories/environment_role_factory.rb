FactoryGirl.define do
  factory :environment_role do
    association :role
    association :environment
  end
end

