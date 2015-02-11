FactoryGirl.define do
  factory :apps_request do
    association :app
    association :request
  end
end
