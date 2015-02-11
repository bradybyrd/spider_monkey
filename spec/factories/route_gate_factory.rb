FactoryGirl.define do
  factory :route_gate do
    sequence(:position) { |p| p }
    association :environment
    association :route
  end
end

