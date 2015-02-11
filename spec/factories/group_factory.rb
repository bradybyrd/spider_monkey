FactoryGirl.define do
  factory :group do
    sequence(:name) { |n| "test group #{n}" }
    sequence(:email) { |n| "testgroup#{n}@bmc.com" }
    active true
    position '4'
    root false

    factory :group_with_roles, parent: :group do |group|
      roles {[FactoryGirl.create(:role)]}

      trait :root do
        root true
      end
    end

    factory :default_group do
      position 1
    end

    trait :with_users do
      ignore do
        user_count 1
      end

      after(:build) do |group, evaluator|
        group.resources << build_list(:user, evaluator.user_count, groups: [group])
      end
    end

  end
end

