FactoryGirl.define do
  factory :note do
    association :user
    sequence(:content) { |n| "Note #{n}" }
  end
end
