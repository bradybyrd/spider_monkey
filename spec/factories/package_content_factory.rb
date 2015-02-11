FactoryGirl.define do
  factory :package_content do
    sequence(:name) { |n| "Package Content #{n}" }
    sequence(:abbreviation) { |n| "pkg#{n}" }
    sequence(:position) { |n| n }
  end
end
