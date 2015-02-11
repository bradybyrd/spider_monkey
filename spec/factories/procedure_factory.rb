FactoryGirl.define do
  factory :procedure do
    sequence(:name) { |n| "Procedure #{n}" }
    aasm_state 'released'
    is_import true
    apps []

    trait :archived do
      aasm_state 'archived_state'
      archived_at Time.now
      sequence(:archive_number) { |n| n }
    end

    trait :draft do
      aasm_state 'archived_state'
    end

    trait :with_steps do
      ignore do
        steps_count 2
      end

      after(:create) do |procedure, evaluator|
        create_list(:step, evaluator.steps_count, :with_procedure, floating_procedure: procedure, request: nil)
      end
    end
  end
end
