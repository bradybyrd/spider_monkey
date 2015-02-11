FactoryGirl.define do
  factory :version_tag_linked_item, class: 'LinkedItem' do
    sequence(:name) { |n| "linked_item_#{n}" }
    association :source_holder, factory: :version_tag
    association :target_holder, factory: :version_tag
  end
end
