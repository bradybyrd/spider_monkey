FactoryGirl.define do
  factory :extended_attribute do
    sequence(:name) { |n| "Value #{n}" }
    value_holder_id 1
    value_holder_type 'InstalledComponent'
  end
end

