FactoryGirl.define do
  factory :activity_phase do
    sequence(:name) { |n| "ActivityPhase #{n}" }
    association :activity_category
  end
end

