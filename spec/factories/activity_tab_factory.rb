FactoryGirl.define do
  factory :activity_tab do
    sequence(:name) { |n| "Activity Tab #{n}" }
    association :activity_category
  end
end

