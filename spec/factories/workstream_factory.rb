FactoryGirl.define do
  factory :workstream do
    association :resource, factory: :user
    association :activity
  end
end
