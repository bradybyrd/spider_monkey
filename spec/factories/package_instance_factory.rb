FactoryGirl.define do
  factory :package_instance do
    sequence(:name) { |n| "0.0.0.#{n}" }
    association :package
    active true

    trait :with_properties do
      properties { [FactoryGirl.create(:property)] }
    end
  end
end


