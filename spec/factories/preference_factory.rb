FactoryGirl.define do
  factory :preference do
    association :user
    sequence(:text) { |n| "Preference #{n}" }
    sequence(:position) { |n| n }
    active true
    preference_type "Request"
    string "Request"
  end
end

