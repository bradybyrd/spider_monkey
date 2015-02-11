FactoryGirl.define do
  factory :environment_type do
    sequence(:name) { |n| "Environment Type #{n}" }
    sequence(:position) { |p| p }
  end
end

