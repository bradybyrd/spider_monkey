FactoryGirl.define do
  factory :application_environment do
    association :app
    association :environment
    sequence(:position) { |n| n }
    different_level_from_previous 1
    updated_at Time.now
    created_at Time.now
  end
end

