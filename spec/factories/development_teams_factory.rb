FactoryGirl.define do
  factory :development_team do
    association :team
    association :app
  end
end

