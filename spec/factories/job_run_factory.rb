FactoryGirl.define do
  factory :job_run do
    job_type 'automation'
    status 'Starting'
    run_key 1323073373
    user_id 1
    automation_id 1
    step_id 1
    started_at '2011-12-05 08:22:53'
    created_at '2011-12-05 08:22:53'
    updated_at '2011-12-05 08:22:53'
  end
end

