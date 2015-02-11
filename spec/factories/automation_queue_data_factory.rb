some_time = Time.now

FactoryGirl.define do
  factory :automation_queue_data do
    attempts 0
    last_error nil
    run_at some_time
    step_id 1
  end
end

