FactoryGirl.define do
  factory :plan_stage_status do
    sequence(:name) { |n| "Plan Stage Status #{n}"}
    sequence(:position) { |n| n }
  end
end