FactoryGirl.define do
  factory :deployment_window_occurrence, class: DeploymentWindow::Occurrence do
    start_at Time.zone.now + 1.day
    finish_at Time.zone.now + 3.days

    trait :passed_in_time do
      start_at Time.now - 2.day
      finish_at Time.now - 1.days
    end
  end
end
