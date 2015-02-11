FactoryGirl.define do
  factory :deployment_window_event, class: DeploymentWindow::Event do
    start_at Time.now + 1.day
    finish_at Time.now + 2.days

    trait :passed_in_time do
      start_at Time.now - 2.day
      finish_at Time.now - 1.days
    end

    trait :with_allow_series do
      after(:create) do |instance|
        dws               = create :deployment_window_series, behavior: DeploymentWindow::Series::ALLOW
        environment       = create(:environment, :closed)
        occurrence        = create :deployment_window_occurrence, environment_ids: [environment.id]
        occurrence.series = dws
        occurrence.events = [instance]
        occurrence.save
      end
    end
  end
end
