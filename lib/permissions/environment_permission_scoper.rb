require 'accessible_app_environment_query'
require 'permission_map'

class EnvironmentPermissionScoper
  attr_reader :user, :obj_scope

  class << self
    attr_reader :scopes

    def scope_for(subject, &block)
      @scopes ||= {}
      @scopes[subject.to_s] = block
    end
  end

  scope_for('Request') {|obj_scope, envs_selector|
    request_ids = Request.select('DISTINCT request_id')
      .joins('INNER JOIN apps_requests internal_apps_requests on requests.id = internal_apps_requests.request_id')
      .joins('INNER JOIN application_environments int_app_envs on int_app_envs.app_id = internal_apps_requests.app_id and int_app_envs.environment_id = requests.environment_id')
      .extending(QueryHelper::WhereIn)
      .where_in('int_app_envs.id', PermissionMap.instance.accessible_ids_per_app_environment(envs_selector, :id).presence || [-1])
    obj_scope.joins("JOIN (#{request_ids.to_sql}) accessible_requests ON accessible_requests.request_id = requests.id")
  }

  scope_for('Server') {|obj_scope, envs_selector|
    accessible_env_ids = PermissionMap.instance.accessible_ids_per_app_environment(envs_selector, :environment_id)
    obj_scope.select("DISTINCT servers.*").
              joins(:environment_servers).
              where(environment_servers: { environment_id: accessible_env_ids })
  }

  scope_for('ServerAspectGroup') {|obj_scope, envs_selector|
    accessible_envs = envs_selector.accessible_env_ids.to_sql
    obj_scope.joins(:server_aspects => :environment_servers).
        where("environment_servers.environment_id in(#{accessible_envs})").
        uniq
  }

  scope_for('DeploymentWindow::Series') {|obj_scope, envs_selector|
    accessible_envs = envs_selector.accessible_env_ids.to_sql
    query = DeploymentWindow::Series.select("DISTINCT deployment_window_series.id")
                                    .joins(:events)
                                    .where("deployment_window_events.environment_id in(#{accessible_envs})")
    obj_scope.joins("INNER JOIN (#{query.to_sql}) user_series ON user_series.id = deployment_window_series.id")
  }

  def initialize(user, obj_scope)
    @user = user
    @obj_scope = obj_scope
  end

  def entities_by_ability(action)
    get_scope.call(obj_scope, environment_selector(action))
  end

  def environment_selector(action)
    AccessibleAppEnvironmentQuery.new(@user, action, scope_subject)
  end

  protected

  def get_scope
    self.class.scopes[scope_subject]
  end

  def scope_subject
    obj_scope.klass.to_s
  end
end
