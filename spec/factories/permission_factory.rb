FactoryGirl.define do
  factory :permission do
    sequence(:name) { |n| "Permission#{n}" }
    action 'view'
    sequence(:subject) { |n| "Subject#{n}" }
    initialize_with { Permission.where(name: name).first_or_initialize }
  end
end
