FactoryGirl.define do
  factory :property_value do
    sequence(:value) { |n| "Value #{n}" }
    association :property
    value_holder_id 1
    value_holder_type 'Component'
  end
end

