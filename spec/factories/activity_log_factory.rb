FactoryGirl.define do
  factory :activity_log do
    usec_created_at   Time.now.usec
    association :request
    activity    "Test Activity"
    association :user
    created_at Time.now
  end
end