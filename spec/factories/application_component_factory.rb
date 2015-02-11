FactoryGirl.define do
  factory :application_component do
    sequence(:position) { |n| n }
    association :app
    association :component
    different_level_from_previous 1
    updated_at Time.now
    created_at Time.now
  end
end

