require 'torquebox-cache'
require "accessible_app_environment_query"
require "accessible_app_query"

class PermissionMap
  include Singleton

  KEYS = [
    GLOBAL_KEY = :global,
    APP_KEY = :application,
    APP_ENV_KEY = :application_environment
  ]

  def initialize
    @permissions = TorqueBox::Infinispan::Cache.new(name: 'permissions', mode: :distributed)
    @user_permissions = TorqueBox::Infinispan::Cache.new(name: 'user_permissions', mode: :distributed)
    register_permissions
  end

  def has_user_global_access?(user, subject, action)
    user_permissions_by_subject = user_permissions_by_subject(user)
    user_permissions_by_subject[subject].any?{|permissions| permissions[:action] == action.to_s }
  end

  def has_any_app_access_for_apps?(user, subject, action, app_ids)
    is_data_cached?(user, subject, action, APP_KEY) { |cached_app_ids| (cached_app_ids & app_ids).present? }
  end

  def has_any_app_env_access_for_app_envs?(user, subject, action, object_app_env_ids)
    is_data_cached?(user, subject, action, APP_ENV_KEY) { |cached_user_app_env_data| (cached_user_app_env_data[:id] & object_app_env_ids).present? }
  end

  def has_all_app_env_access_for_app_envs?(user, subject, action, app_env_ids)
    is_data_cached?(user, subject, action, APP_ENV_KEY) do |cached_data|
      (cached_data[:id] & app_env_ids).sort == app_env_ids.sort
    end
  end

  def has_all_environments_access?(user, subject, action, env_ids)
    is_data_cached?(user, subject, action, APP_ENV_KEY) do |cached_data|
      (cached_data[:environment_id] & env_ids).sort == env_ids.sort
    end
  end

  def has_any_environments_access?(user, subject, action, env_ids)
    is_data_cached?(user, subject, action, APP_ENV_KEY) do |cached_data|
      (cached_data[:environment_id] & env_ids).present?
    end
  end

  def get_global_permissions(user)
    get_user_permissions(user).values.collect{|el| get_permission(el[GLOBAL_KEY])}.compact
  end

  def get_permission(id)
    raise ArgumentError.new("Couldn't find permission by id is wrong: #{id.inspect}") unless id && id > 0
    @permissions.get(id)
  end

  def get_user_permissions(user)
    @user_permissions.contains_key?(user.id) ? @user_permissions.get(user.id) : cache_user_permissions(user)
  end

  def clean(user)
    @user_permissions.remove(user.id)
    Rails.cache.delete([:user_permissions_by_subject, user.id])
  end

  def bulk_clean(users)
    users.each{ |user| clean(user) }
  end

  def global_permissions_hash(user)
    hash = {}
    UserPermissionsQuery.new(user).user_permissions.each do |permission|
      key = stored_key(permission.subject, permission.action)
      hash[key] = {}
      hash[key][GLOBAL_KEY] = permission.id
    end
    hash
  end

  def get_stored_values(subject, action, user, key)
    cache_key = stored_key(subject, action)
    get_user_permissions(user)[cache_key][key]
  end

  def accessible_ids_per_app_environment(object, ids_from)
    args = [object.subject, object.action, object.user, APP_ENV_KEY]
    hash = get_stored_values(*args)
    hash && hash[ids_from] || []
  end

  def user_permissions_by_subject(user)
    Rails.cache.fetch([:user_permissions_by_subject, user.id]) do
      UserPermissionsQuery.new(user).user_permissions.group_by { |el| el[:subject] }
    end
  end

  private

  def cache_user_permissions(user)
    hash = global_permissions_hash(user)
    set_application_environment_permissions(user, hash)
    set_application_permissions(user, hash)

    @user_permissions.put(user.id, hash)
    hash
  end

  def set_application_environment_permissions(user, hash)
    user_application_environments_with_permissions(user).each do |application_environment|
      key = stored_key(application_environment.subject, application_environment.action)
      hash[key] ||= {}
      hash[key][APP_ENV_KEY] ||= {id: [], environment_id: [], app_id: []}
      sub_hash = hash[key][APP_ENV_KEY]
      sub_hash[:id]             << application_environment.id             unless sub_hash[:id].include?(application_environment.id)
      sub_hash[:environment_id] << application_environment.environment_id unless sub_hash[:environment_id].include?(application_environment.environment_id)
      sub_hash[:app_id]         << application_environment.app_id         unless sub_hash[:app_id].include?(application_environment.app_id)
    end
    hash
  end

  def user_application_environments_with_permissions(user)
    query = AccessibleAppEnvironmentQuery.new(user)
    columns = %W( permissions.subject permissions.action application_environments.id
                  application_environments.environment_id application_environments.app_id)
    array = query.accessible_app_envs_with_user.select("DISTINCT #{columns.join(', ')}")
  end

  def set_application_permissions(user, hash)
    query = AccessibleAppQuery.new(user)
    columns = %w(permissions.subject permissions.action apps.id)
    array = query.accessible_apps_with_user.
      select("DISTINCT #{columns.join(', ')}").all
    array.each do |row|
      key = stored_key(row.subject, row.action)
      hash[key] ||= {}
      hash[key][APP_KEY] ||= []
      hash[key][APP_KEY] << row.id unless hash[key][APP_KEY].include?(row.id)
    end
    hash
  end

  def stored_key(subj, action)
    "#{subj}_|_#{action}"
  end

  def register_permissions
    Permission.all.each{|p| @permissions.put(p.id, p.to_simple_hash)}
  end

  # allow to check conditions with data from hash by appropriate key
  # condition should return true or false
  def is_data_cached?(user, subject, action, key, &block)
    specific_permissions_hash = get_stored_values(subject, action, user, key)
    specific_permissions_hash.present? && block.call(specific_permissions_hash)
  end
end
