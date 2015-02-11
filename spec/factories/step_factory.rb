FactoryGirl.define do
  factory :step do
    sequence(:name) { |n| "Step #{n}" }
    different_level_from_previous true
    manual true
    description "A sample step description."
    procedure false
    should_execute true
    suppress_notification false
    association :owner, :factory => :user
    association :request
    factory :step_with_script do |step|
      step.association :script,   factory: :general_script
      step.association :request,  factory: :request_with_app
    end

    trait :with_procedure do
      association :floating_procedure, factory: :procedure
    end
  end
end
