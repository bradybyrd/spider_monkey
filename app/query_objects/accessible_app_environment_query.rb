class AccessibleAppEnvironmentQuery < AccessibleBaseQuery
  attr_reader :user, :action, :subject

  def accessible_app_envs
    add_permission_scope(accessible_app_envs_with_user)
  end

  def accessible_app_envs_with_user
    add_user_scope(app_env_by_team_role_scope)
  end

  def app_env_by_team_role_scope
    ApplicationEnvironment.joins(app: { teams: { team_groups: { group: [:resources, roles: :permissions] }}}).
      joins('LEFT JOIN team_group_app_env_roles on team_group_app_env_roles.team_group_id = team_groups.id and application_environments.id = team_group_app_env_roles.application_environment_id').
      where('COALESCE(team_group_app_env_roles.role_id, group_roles.role_id) = group_roles.role_id').
      where(teams: { active: true }).
      where(groups: { active: true })
  end

  def accessible_env_ids
    accessible_app_envs.select('distinct application_environments.environment_id')
  end

  def accessible_app_env_ids
    accessible_app_envs.select('distinct application_environments.app_id, application_environments.environment_id')
  end
end
