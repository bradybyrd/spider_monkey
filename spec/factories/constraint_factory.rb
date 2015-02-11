FactoryGirl.define do
  factory :constraint do
    association :governable, factory: :plan_stage
    association :constrainable, factory: :route_gate
  end
end