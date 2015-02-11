FactoryGirl.define do
  factory :property_work_task do
    association :property
    association :work_task
    entry_during_step_execution false
    entry_during_step_creation false
    created_at Time.now
    updated_at Time.now
  end
end
