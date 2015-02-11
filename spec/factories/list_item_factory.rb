FactoryGirl.define do
  factory :list_item do
    value_text 'permanent'
    is_active 'true'
    association :list
  end
end