class UserPermissionsQuery
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def get_all
    user_permissions.all
  end

  def get_by_subject_and_action(subject, action)
    user_permissions.where(action: action, subject: subject)
  end

  def user_permissions
    Permission.
      joins(roles: {groups: :users}).
      where(users: {id: user.id}, groups: {active: true}).
      uniq
  end
end
