FactoryGirl.define do
  factory :plan_stage do
    sequence(:name) { |n| "Plan Stage #{n}"}
    association :plan_template
    sequence(:position) { |n| n }
    association :environment_type
  end
end