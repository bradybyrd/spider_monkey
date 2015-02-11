FactoryGirl.define do
  factory :component do
    sequence(:name) { |n| "Component #{n}" }

    trait :active do
      active true
    end
  end
end
