FactoryGirl.define do
  factory :package do
    sequence(:name) { |n| "Package #{n}" }
    next_instance_number 1
    instance_name_format "0.0.0.[#]"

    trait :with_properties do
      properties { [FactoryGirl.create(:property)] }
    end
  end
end

