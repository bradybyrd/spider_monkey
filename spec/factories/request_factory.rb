FactoryGirl.define do
  factory :request do
    sequence(:name) { |n| "Test Request #{n}" }
    association :deployment_coordinator, :factory => :user
    association :requestor, :factory => :user
    association :owner, :factory => :user
    association :plan_member
    association :environment
    additional_email_addresses DEFAULT_SUPPORT_EMAIL_ADDRESS
    updated_at Time.zone.now
    notify_on_request_start false
    notify_on_step_complete false
    notify_on_step_start false
    aasm_state 'created'
    business_process_id 1
    notify_on_request_complete false
    created_at Time.zone.now
    ignore do
      notes_count 2
      user
    end

    factory :request_with_app do
      after(:create) do |request|
        app = create(:app, environments: [request.environment])
        request.apps = [app]
      end
    end

    trait :with_assigned_app do
      after(:create) do |request, evaluator|
        team = create(:team, groups: [evaluator.user.groups.first])
        app = create(:app, teams:[team], environments: [request.environment])
        team.apps = [app]
        app.users = [evaluator.user]
        request.apps = [app]
      end
    end

  end
end
