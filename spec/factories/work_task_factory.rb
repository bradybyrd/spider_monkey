FactoryGirl.define do
  factory :work_task do
    sequence(:name) { |n| "Test Task #{n}" }
    updated_at Time.now
    sequence(:position) { |n| n }
    created_at Time.now
  end
end
