FactoryGirl.define do
  factory :component_property do
    association :component
    association :property
    #association :active_property
  end
end

