class UserQuery
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def users_with_access_to_apps_and_environment(app_ids, environment_id, options = {})
    ignore_access?(options) { users_having_access_to_apps_and_environment(app_ids, environment_id) }
  end

  def users_with_access_to_apps(app_ids, options = {})
    ignore_access?(options) { users_having_access_to_apps(app_ids) }
  end

  private

  def ignore_access?(options)
    if options.fetch(:ignore_access, false)
      active_users
    else
      root_users_and { yield }
    end
  end

  def active_users
    User.active
  end

  def active_root_users
    active_users.admins
  end

  def root_users_and
    user_ids = active_root_users.pluck('users.id')
    user_ids |= yield.pluck('users.id')

    user_ids.empty? ? User.where(id: nil) : User.scoped.extending(QueryHelper::WhereIn).where_in(:id, user_ids)
  end

  def users_having_access_to_apps_and_environment(app_ids, environment_id)
    active_users.joins(apps: :environments).
      where(assigned_apps: {app_id: app_ids}).
      where(environments: {id: environment_id})
  end

  def users_having_access_to_apps(app_ids)
    active_users.joins(:apps).where(assigned_apps: {app_id: app_ids})
  end
end