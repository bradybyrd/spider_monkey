FactoryGirl.define do
  factory :plan do
    sequence(:name) { |n| "Plan #{n}" }
    plan_template
    description 'a sample plan'
    release_date Time.now
  end
end

