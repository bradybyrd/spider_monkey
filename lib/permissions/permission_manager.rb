require 'permission_granters'
require 'model_permissions'
require 'permissions_list'
require 'user_permissions_query'
require 'permission_map'
require 'global_permissions'
require 'model'

class PermissionManager
  attr_reader :user

  # will fetch instance of appropriate class to process permission, like EnvironmentPermissionGranter, etc...

  # Note:
  # Only subjects should be configured here (no permissions)
  # Let's configure in this way: firstly not model Subjects after that, model subjects
  # Please figure out what is proper restriction rule for appropriate subject before put in appropriate restriction group
  RESTRICTIONS = {
    global: %w(
      my_applications main_tab dashboard_tab plans_tab requests_tab reports_tab
      applications_tab environment_tab system_tab
      app_component_summary_map maps_reports my_environments my_servers
      my_requests dashboard_calendar dashboard_promotions running_steps
      calendar release_calendar environment_calendar deployment_windows_calendar
      process_reports time_to_complete_report time_to_problem_report
      component_versions_map properties_map servers_map_by_app server_map
      roles_map metadata settings statistics automation_monitor volume_report
      problem_trend_report access_reports roles_map_report automation server_tabs
      Activity Run Ticket Plan Category User ComponentTemplate
      Group Team Role ProjectServer IntegrationProject PlanRoute Route
      Constraint Phase Property EnvironmentType PlanTemplate Procedure
      PackageContent Release List BusinessProcess VersionTag ServerLevel
      ServerAspect ServerGroup WorkTask GlobalSettings AutomationQueueData
      NotificationTemplate PlanStage Step Package Reference
      ),
    application: %w(
      App ApplicationComponent ApplicationEnvironment Environment ApplicationPackage
      Component RequestTemplate PackageInstance
      ),
    environment: %w(InstalledComponent Request DeploymentWindow::Series),
    multiple_environments: %w(Server ServerAspectGroup)
  }

  def initialize(ability, user = User.current_user)
    @ability = ability
    @granters = Hash[RESTRICTIONS.keys.collect { |key| [key, get_klass("#{key.to_s.camelize}PermissionGranter").new(user)] }]
    @user = user
  end

  def apply_permissions
    user_permissions_by_subject.each do |subject, permissions|
      subject = subject.to_s
      model_flag = model?(subject)
      model = subject.constantize if model_flag

      permissions.each do |permission|
        if model_flag
          register_model_action(permission[:action].to_sym, model)
        else
          register_global_action(permission[:action].to_sym, subject)
        end
      end
    end
  end

  # allow to redefine_behaviour for particular class
  # example for key :main_menu:
  # module Permissions
  #   module GlobalPermissions
  #     class MainMenu
  #       def view_dashboard?(user)
  #          return true or false
  #       end
  #
  #       def view_environment?(user)
  #          return true or false
  #       end
  #     end
  #   end
  # end
  def register_global_action(action, key)
    method_name = "#{action}?"
    perm_class_instance = redefined_global_permissions_class_for(key)
    if perm_class_instance && perm_class_instance.respond_to?(method_name)
      @ability.can action, key.to_sym if perm_class_instance.send(method_name, @user)
    else
      @ability.can action, key.to_sym if permission_granter(key).grant?(action, key)
    end
  end

  # allow to redefine_behaviour for particular class
  # example for model Category:
  # module Permissions
  #   module Model
  #     class CategoryPermissions
  #       def view?(obj, user)
  #          return true or false
  #       end
  #
  #       def create?(obj, user)
  #          return true or false
  #       end
  #     end
  #   end
  # end
  def register_model_action(action, model)
    method_name = "#{action}?"
    perm_model_instance = redefined_permissions_model_for(model)
    if perm_model_instance && perm_model_instance.respond_to?(method_name)
      @ability.can action, model do |obj|
        perm_model_instance.send(method_name, obj, @user)
      end
    else
      @ability.can action, model do |obj|
        if obj.respond_to?(:granter_type)
          granter(obj.granter_type(@user)).grant?(action, obj)
        else
          permission_granter(model).grant?(action, obj)
        end
      end
    end
  end

  def redefined_permissions_model_for(model)
    if Permissions::Model.constants.include?("#{model}Permissions".to_sym)
      perm_class = get_klass("Permissions::Model::#{model}Permissions")
      perm_class.new
    end
  end

  def redefined_global_permissions_class_for(key)
    clazz = key.to_s.camelize
    if Permissions::GlobalPermissions.constants.include?("#{clazz}".to_sym)
      perm_class = get_klass("Permissions::GlobalPermissions::#{clazz}")
      perm_class.new
    end
  end

  def permission_granter(class_name)
    RESTRICTIONS.each do |key, klasses|
      return granter(key) if klasses.include?(class_name.to_s)
    end
    raise ArgumentError.new("Could not find a granter for #{class_name.to_s} class")
    # GlobalPermissionGranter # should be returned instead of the exception raised
  end

  def granter(type)
    @granters[type]
  end

  private

  def model?(model_name)
    (model = get_klass(model_name)) && model.ancestors.include?(ActiveRecord::Base)
  end

  def get_klass(class_name)
    class_name.constantize
  rescue NameError
    Object
  end

  def user_permissions_by_subject
    PermissionMap.instance.user_permissions_by_subject(user)
  end
end
