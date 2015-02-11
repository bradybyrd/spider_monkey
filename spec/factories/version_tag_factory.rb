FactoryGirl.define do
  factory :version_tag do
    association :component
    association :app
    association :application_environment
    association :installed_component

    sequence (:artifact_url) {|n| "http://artifact#{n}.url"}
    sequence (:name){|n| "VersionTag#{n}"}

    trait :proper do
      not_from_rest true

      after(:build) do |version_tag|
        app                                 = create(:app, :with_installed_component)
        version_tag.app_id                  = app.id
        version_tag.app_env_id              = app.application_environments.last.id
        version_tag.installed_component_id  = app.application_components.last.installed_components.last.id
        # version_tag.application_environment = app.application_environments.last
      end
    end
  end

end