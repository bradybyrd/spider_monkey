FactoryGirl.define do
  factory :step_holder do
    association :step
    association :request
    association :change_request
  end
end
