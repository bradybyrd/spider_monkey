FactoryGirl.define do
  factory :deployment_window_series, class: DeploymentWindow::Series do
    sequence(:name) { |n| "deployment window series #{n}" }
    start_at Time.zone.now + 1.day
    finish_at Time.zone.now + 3.days + 30.minutes
    behavior 'allow'
    recurrent false
    aasm_state 'released'
    is_import true
    environment_ids []

    trait :passed_in_time do
      start_at Time.zone.now - 2.day
      finish_at Time.zone.now - 1.days
    end

    trait :with_occurrences do
      ignore do
        environment_ids []
      end
      after(:create) do |instance, evaluator|
        create(:deployment_window_occurrence, series_id: instance.id, start_at: instance.start_at, finish_at: instance.finish_at, environment_ids: evaluator.environment_ids)
      end
    end

    ## TODO: FIX THIS
    ## it do nothing because there are no environment_ids
    trait :with_active_request do
      after(:create) do |instance|
        create(:request, deployment_window_event: instance.events.first, scheduled_at: instance.start_at,
               estimate: (instance.finish_at - instance.start_at) / 60 ) # minutes
      end
    end

    factory :recurrent_deployment_window_series, class: DeploymentWindow::Series do
      finish_at Time.now + 3.days + 1.hour
      recurrent true
      duration_in_days 1
      frequency {{interval: 1, rule_type: 'IceCube::DailyRule'}}

      trait :with_occurrences do
        ignore do
          environment_ids []
        end
        after(:create) do |instance, evaluator|
          3.times do |i|
            start = Time.zone.now + 1.day + i.days
            finish = start + instance.duration

            create(:deployment_window_occurrence,
                   series_id: instance.id,
                   start_at: start,
                   finish_at: finish,
                   environment_ids: evaluator.environment_ids,
                   position: i+1,
                   name: instance.name,
                   behavior: instance.behavior,
                   environment_names: instance.environments.order('environments.name').pluck('environments.name').join(', '))
          end
        end
      end
    end

  end
end
