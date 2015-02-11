FactoryGirl.define do
  factory :apps_business_process do
    association :app
    association :business_process
  end
end

