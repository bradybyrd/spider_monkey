FactoryGirl.define do
  factory :package_template_item do
    sequence(:name) { |n| "Package Template #{n}" }
    sequence(:item_type) { |n| n }
    association :package_template
  end
end