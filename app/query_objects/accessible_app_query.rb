class AccessibleAppQuery < AccessibleBaseQuery
  attr_reader :user, :action, :subject

  def accessible_apps
    add_permission_scope(accessible_apps_with_user)
  end

  def accessible_apps_with_user
    add_user_scope(app_by_team_role_scope)
  end

  def app_by_team_role_scope
    App.
      joins(teams: { team_groups: { group: [:resources, roles: :permissions] }}).
      where(teams: { active: true }).
      where(groups: { active: true })
  end
end
