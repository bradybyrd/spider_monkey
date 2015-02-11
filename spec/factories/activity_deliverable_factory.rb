FactoryGirl.define do
  factory :activity_deliverable do
    sequence(:name) { |n| "Activity Deliverable #{n}" }
    association :activity
    association :deployment_contact, factory: :user
    projected_delivery_on DateTime.now.to_s
    release_deployment false
  end
end
