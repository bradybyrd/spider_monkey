FactoryGirl.define do
  factory :assigned_app do
    association :app
    association :team
    association :user
  end
end
