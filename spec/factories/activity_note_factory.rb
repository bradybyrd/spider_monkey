FactoryGirl.define do
  factory :activity_note do
    contents "A note"
    association :user
    association :activity
  end
end
