FactoryGirl.define do
  factory :server_level do
    description "A test server level description"
    sequence(:position) { |n| n }
    sequence(:name) { |n| "Server Level #{n}" }
  end
end

