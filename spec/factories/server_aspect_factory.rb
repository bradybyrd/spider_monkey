FactoryGirl.define do
  factory :server_aspect do
    association :parent, :factory => :server
    association :server_level
    description "A test server aspect."
    sequence(:name) { |n| "Server Aspect #{n}" }
  end
end

