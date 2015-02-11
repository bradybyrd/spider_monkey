FactoryGirl.define do
  factory :instance_reference do
    sequence(:name) { |n| "InstanceReference #{n}" }
    association :server
    association :package_instance
    association :reference
    uri 'test'
  end
end
