class UserGroupsPresenter
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def to_sym
    :"#{user.class.name.underscore}"
  end

  def listable_props
    user.groups.map { |g| g.name }
  end
end
