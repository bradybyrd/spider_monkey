FactoryGirl.define do
  factory :plan_team do
    association :plan
    association :team
  end
end
