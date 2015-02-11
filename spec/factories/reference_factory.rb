FactoryGirl.define do
  factory :reference do
    sequence(:name) { |n| "Reference #{n}" }
    uri 'www.example.com'
    association :server
    association :package
  end
end
