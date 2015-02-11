FactoryGirl.define do
  factory :property do
    sequence(:name) { |n| "Property #{n}" }
    active

    trait :active do
      active true
    end

    trait :inactive do
      active false
    end
  end
end

