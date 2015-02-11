FactoryGirl.define do
  factory :notification_template do
    title       'User Forgot Login'
    sequence(:event) { |n| Notifier.supported_events[n % Notifier.supported_events.size] }
    sequence(:format) { |n| Notifier.supported_formats[n % Notifier.supported_formats.size] }
    subject     'A subject line'
    description 'A testing template'
    body        'My template: {{hello_world}}'
    active      true
  end
end