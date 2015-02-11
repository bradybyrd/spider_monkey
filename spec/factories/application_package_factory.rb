FactoryGirl.define do
  factory :application_package do
    association :app
    association :package

    trait :with_properties do
      association :package, :with_properties
    end
  end
end
