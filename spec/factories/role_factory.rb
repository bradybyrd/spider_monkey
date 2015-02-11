FactoryGirl.define do
  factory :role do
    sequence(:name) { |n| "Role#{n}" }
    description 'description'

    factory :role_with_permissions, parent: :role do |role|
      permissions {[FactoryGirl.create(:permission)]}
      after(:create) do |r, evaluator|
        r.permissions << evaluator.permissions
      end
    end
  end
end
