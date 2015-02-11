FactoryGirl.define do
  factory :plan_member do
    association :plan
    association :stage, :factory => :plan_stage
  end
end
