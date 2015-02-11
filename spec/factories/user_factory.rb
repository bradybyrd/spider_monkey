FactoryGirl.define do
  factory :user, aliases: [:requestor, :deployment_coordinator, :owner] do |f|
    sequence(:login) { |n| "login#{n}" }
    sequence(:first_name) { |n| "Jane_#{n}" }
    sequence(:last_name) { |n| "Smith_#{n}" }
    email { "#{first_name}.#{last_name}@example.com".downcase }
    password 'password1'
    password_confirmation { password }
    employment_type 'permanent'
    first_time_login false
    created_at { Time.now }
    active true
    password_salt 'a981220357001a75aea1b3dfc74e59727aae8186'
    updated_at { Time.now }
    location { List.get_list_items("Locations").sort.first }

    after(:build) { |user| user.class.skip_callback(:create, :after, :send_welcome_email) }
    after(:build) { |user| user.class.skip_callback(:update, :after, :send_notification_email) }
    after(:build) { |user| user.stub(:new_password_validation).and_return true }

    trait :with_callbacks do
      after(:build) { |user| user.class.set_callback(:create, :after, :send_welcome_email) }
      after(:build) { |user| user.class.set_callback(:update, :after, :send_notification_email) }
    end

    # TODO: remove old_user factory
    factory :old_user do
      trait :not_admin_with_role_and_group do
        admin false
        root false
        groups { [FactoryGirl.create(:group_with_roles)] }
      end
    end

    trait :non_root do
      groups { [create(:group, root: false)] }
    end

    trait :root do
      after(:build) do |user|
        user.groups << create(:group, root: true)
      end
    end

    trait :with_component do
      apps { [create(:app, components: [create(:component)])] }
    end

    trait :with_role_and_group do
      groups { [create(:group_with_roles)] }
    end

    trait :with_role_and_root_group do
      groups { [create(:group_with_roles, :root)] }
    end

    trait :with_all_permissions do
      non_root
      after(:create) do |user|
        role = create(:role, permissions: Permission.all)
        group = user.groups.last || create(:group)
        group.roles = [role]
        team = user.teams.last || create(:team)
        team.groups = [group]
        user.reload
      end
    end

  end
end
