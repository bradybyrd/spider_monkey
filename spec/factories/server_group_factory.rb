FactoryGirl.define do
  factory :server_group do
    sequence(:name) { |n| "Server Group #{n}" }
    description "A test server group"
    active true
  end
end

