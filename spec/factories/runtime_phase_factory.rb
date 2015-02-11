FactoryGirl.define do
  factory :runtime_phase do
    sequence(:name) { |n| "RuntimePhase #{n}" }
    association :phase
  end
end