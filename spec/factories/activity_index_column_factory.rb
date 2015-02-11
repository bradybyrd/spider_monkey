FactoryGirl.define do
  factory :activity_index_column do
    #sequence(:activity_attribute_column) do |n|
    #  ActivityIndexColumn.available_attributes[n % ActivityIndexColumn.available_attributes.length]
    #end
    activity_attribute_column 'name'
    association :activity_category
  end
end
