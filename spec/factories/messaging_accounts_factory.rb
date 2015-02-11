# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :messaging_account do
    service "MyString"
    account "MyString"
    active true
    primary_account false
    association :user
  end
end
