FactoryGirl.define do
  factory :list do
    sequence(:name) { |n| "List #{n}" }
    is_text true
  end
end

