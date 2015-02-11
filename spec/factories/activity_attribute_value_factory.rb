FactoryGirl.define do
  factory :activity_attribute_value do
    association :activity
    association :activity_attribute
  end
end
