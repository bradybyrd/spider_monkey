FactoryGirl.define do
  factory :server_aspect_group do
    sequence(:name) { |n| "Server Aspect Group #{n}" }
  end
end

