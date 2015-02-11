class MultipleEnvironmentsPermissionGranter < PermissionGranter
  set_key :environment_ids

  value_for(Server) { |server, user| server.environments_per_application_environment_apps_for(user).map(&:id) }
  value_for(ServerAspectGroup) { |server_aspect_group, user| server_aspect_group.environments_per_server_aspects_for(user).map(&:id) }

  def grant?(action, obj)
    subject, environment_ids = PermissionGranter.get_subject(obj), get_values_for(obj, @user)
    if environment_ids.empty?
      permission_map.has_user_global_access?(@user, subject, action)
    else
      has_access_to_environments?(subject, action, environment_ids)
    end
  end

  private

  def has_access_to_environments?(subject, action, ids)
    if action.to_sym == :create
      permission_map.has_all_environments_access?(@user, subject, action, ids)
    else
      permission_map.has_any_environments_access?(@user, subject, action, ids)
    end
  end
end
