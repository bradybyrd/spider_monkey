################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class User < ActiveRecord::Base

  def self.having_access_to(app_ids, environment_id, options={})
    current_user.query_object.users_with_access_to_apps_and_environment(app_ids, environment_id, options)
  end

  def self.having_access_to_apps(app_ids, options={})
    current_user.query_object.users_with_access_to_apps(app_ids, options)
  end

  def accessible_environments(return_all=false)
    return Environment.active.order('LOWER(name) asc') if admin?
    @accessible_envs = Environment.accessible_to_user(id, nil)
    return_all ? @accessible_envs : @accessible_envs.active
  end

  def inactive_accessible_environments
    return Environment.inactive if admin?
    @inactive_accessible_envs = @accessible_envs || accessible_environments(true)
    @inactive_accessible_envs = @inactive_accessible_envs.inactive
  end

  def accessible_default_environments
    return Environment.active if admin?
    accessible_environments.active.all
  end

  def apps_with_environment(environment_ids)
    apps.all(joins: ['INNER JOIN application_environments ON application_environments.app_id = assigned_apps.app_id'],
             conditions: {'application_environments.environment_id' => environment_ids})
  end

  def accessible_apps
    return App.active.order('LOWER(name) asc') if admin?
    apps.active
  end

  def accessible_apps_with_installed_components
    apps.active.with_installed_components
  end

  def inactive_accessible_apps
    return App.inactive.name_order if admin?
    apps.inactive
  end

  def accessible_apps_for_requests
    if admin?
      App.active.with_installed_components.name_order
    else
      apps.active.with_installed_components
    end
  end

  def accessible_apps_for_requests_with_package_templates
    if admin?
      App.active.with_package_templates.name_order
    else
      apps.active.with_package_templates
    end
  end

  def accessible_visible_installed_components_for_app(app)
    if User.current_user.admin?
      @components = app.components
    else
      @components = Component.installed_components_on_app
      @components = @components.accessible_components_for_app(app.id)
      @components = @components.accessible_components_to_user(id)
      @components.select('DISTINCT components.*')
    end
  end

  def accessible_visible_environments_of_app(app)
    return app.environments if admin?
    @accessible_visible_environments = Environment.accessible_to_user(id, app.id)
  end

  def accessible_visible_applications_for_env(environment)
    return environment.apps if admin?
    App.accessible_to_user_for_env(environment).apps_accessible_to_user(id).uniq
  end

  def accessible_components
    return Component.order('LOWER(name) asc').scoped if admin?
    Component.accessible_components_to_user(id).select('DISTINCT components.*')
  end

  def accessible_packages
    return Package.order('LOWER(name) asc').scoped if admin?
    Package.accessible_packages_to_user(id).select('DISTINCT packages.*')
  end

  def accessible_package_instances(package_id)
    return PackageInstance.where(package_id: package_id).order('LOWER(name) asc').scoped if admin?
    PackageInstance.accessible_instances_of_package(self.id, package_id).select('DISTINCT package_instances.*')
  end

  #TODO: from kukula: I don't think it's good design decision to place this methods to User model
  # and than call methods from needed model. I think it'll be better to uses some policy class
  # that knows about user and entity. e.g: ServerPolicy.new(user).scopped
  # and it's better to test that stuf
  def accessible_servers
    Server.by_ability(:list, self)
  end

  def accessible_server_objects
    server_objects=[]
    accessible_environments.collect { |e| server_objects << e.servers }
  end

  def accessible_server_aspect_groups
    ServerAspectGroup.by_ability(:list, self).order('server_aspect_groups.name asc')
  end

  def direct_access_to_app?(app)
    @direct_access_to_app = assigned_apps.where('assigned_apps.team_id IS NULL').find_by_app_id(app.id)
  end

  def access_via_team?(app)
    @access_to_app_via_team = assigned_apps.team_id_not_null.find_by_app_id(app.id)
  end

  def acccess_to_app?(app, team_id)
    @access_to_app = assigned_apps.find_by_app_id_and_team_id(app.id, team_id)
  end

  def set_access_to_app(app, team_id=nil)
    unless acccess_to_app?(app, team_id)
      @assigned_app = assigned_apps.create(app_id: app.id, team_id: team_id)
    end
  end

  def remove_direct_access_of_app(app)
    if direct_access_to_app?(app)
      AssignedApp.delete_with_callback("assigned_apps.id = #{@direct_access_to_app.id}")
    end
  end

  def get_disabled_environments(app, environments)
    environments.select { |env|
      cannot?(:create, Request.new( app_ids: [app.id], environment_id: env.id) )
    }
  end

end
