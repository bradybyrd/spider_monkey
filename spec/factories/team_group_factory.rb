FactoryGirl.define do
  factory :team_group do
    association :team
    association :group
  end
end