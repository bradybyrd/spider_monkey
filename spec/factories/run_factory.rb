FactoryGirl.define do
  factory :run do
    sequence(:name) { |n| "Run #{n}" }
    owner
    requestor
    plan

    after :build do |run|
      run.plan_stage create(:plan_stage, :plan_template => run.plan.plan_template)
    end
  end
end
