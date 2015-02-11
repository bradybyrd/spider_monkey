FactoryGirl.define do
  factory :environment_server do
    default_server false

    trait :with_server do
      association :server
    end

    trait :with_server_aspect do
      association :server_aspect
    end
  end
end
