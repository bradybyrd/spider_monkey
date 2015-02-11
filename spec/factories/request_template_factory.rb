FactoryGirl.define do
  factory :request_template do
    sequence(:name) { |n| "Request Template #{n}" }
    updated_at  Time.now
    created_at  Time.now
    association :request
    aasm_state  'released'
    is_import true
  end
end
