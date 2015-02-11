FactoryGirl.define do
  factory :release do
    sequence(:name) { |n| "Release #{n}" }
  end
end

