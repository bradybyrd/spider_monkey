FactoryGirl.define do
  factory :plan_template do
    sequence(:name) { |n| "Plan Template #{n}" }
    template_type 'deploy'
    aasm_state  'released'
    is_import true
  end
end

