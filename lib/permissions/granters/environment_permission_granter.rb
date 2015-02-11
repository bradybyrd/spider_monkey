require 'accessible_app_environment_query'
require 'user_permissions_query'

class EnvironmentPermissionGranter < PermissionGranter
  set_key :application_environment_id

  value_for(DeploymentWindow::Series) { |deployment_window_series| application_environment_ids(deployment_window_series) }
  value_for(Component) { |component| component.installed_components.map(&:application_environment_id) }
  value_for(Request) do |request|
    request.unassigned? ? [] : request.application_environments.map(&:id)
  end

  def grant?(action, obj)
    subject = PermissionGranter.get_subject(obj)
    if (values = get_values_for(obj)).empty?
      PermissionMap.instance.has_user_global_access?(@user, subject, action)
    else
      if action.to_sym == :create
        PermissionMap.instance.has_all_app_env_access_for_app_envs?(@user, subject, action, values)
      else
        PermissionMap.instance.has_any_app_env_access_for_app_envs?(@user, subject, action, values)
      end
    end
  end

  def self.application_environment_ids(deployment_window_series)
    ApplicationEnvironment.where(environment_id: deployment_window_series.environment_ids).pluck(:id)
  end

  private_class_method :application_environment_ids
end
