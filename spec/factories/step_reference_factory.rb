FactoryGirl.define do
  factory :step_reference do
    association :step
    association :reference
    owner_object_id :owner_object_id
    owner_object_type :owner_object_type
  end
end
