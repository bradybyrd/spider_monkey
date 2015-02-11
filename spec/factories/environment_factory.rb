FactoryGirl.define do
  factory :environment do
    sequence(:name) { |n| "Environment #{n}" }

    trait :closed do
      deployment_policy 'closed'
    end

    trait :opened do
      deployment_policy 'opened'
    end
  end
end

