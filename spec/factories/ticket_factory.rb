FactoryGirl.define do
  factory :ticket do
    sequence(:foreign_id) { |n| "Ticket #{n}" }
    sequence(:name) { |n| "This is Ticket #{n}" }
    association :project_server
  end
end

