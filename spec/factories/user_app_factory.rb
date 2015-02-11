FactoryGirl.define do
  factory :user_app do
    association :app
    association :user
    visible true
  end
end