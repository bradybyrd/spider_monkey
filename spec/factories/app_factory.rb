FactoryGirl.define do
  factory :app do
    sequence(:name) { |n| "Application #{n}" }
    app_version "1"

    factory :default_app do
      id 0
    end

    trait :with_installed_component do
      components    { [create(:component)] }
      environments  { [create(:environment)] }

      after(:create) do |app|
        app.application_components.last.installed_components.create(application_environment_id: app.application_environments.last.id)
      end
    end

    trait :with_procedures do
      after(:create) do |app, _|
        [ create(:procedure, :with_steps, { apps: [app] }),
          create(:procedure, :archived, { apps: [app] }),
          create(:procedure, :draft, { apps: [app] }) ]
      end
    end
  end
end
