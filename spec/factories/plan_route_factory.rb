FactoryGirl.define do
  factory :plan_route do
    association :plan
    association :route
  end
end