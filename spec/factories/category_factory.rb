FactoryGirl.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    categorized_type 'request'
    associated_events ['problem']
  end
end

