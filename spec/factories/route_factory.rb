FactoryGirl.define do
  factory :route do
    sequence(:name) { |n| "Route #{n}" }
    association :app
    route_type  'open'
  end
end

