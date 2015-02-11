################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class App < ActiveRecord::Base
  include SoftDelete
  include WithDefault
  include ApplicationHelper
  include QueryHelper
  include FilterExt

  DEFAULT_APP_ID = 0

  has_many :apps_requests, :dependent => :destroy
  has_many :requests, :through => :apps_requests

  has_many :application_environments,
    order: 'application_environments.position',
    dependent: :destroy

  has_many :application_packages, :order => 'application_packages.position', :dependent => :destroy
  has_many :packages, :through => :application_packages, :order => 'application_packages.position'

  has_many :environments, :through => :application_environments, :order => 'application_environments.position'
  has_many :application_components, :order => 'application_components.position', :dependent => :destroy
  has_many :components, :through => :application_components, :order => 'application_components.position'
  has_many :installed_components, :through => :application_components
  has_many :version_tags, :foreign_key => 'app_id'
  has_many :available_components, through: :application_environments, source: :components
  has_many :environment_components, through: :application_environments, source: :installed_components

  has_and_belongs_to_many :active_procedures, class_name: 'Procedure',
                          conditions: "procedures.aasm_state != 'draft' AND procedures.aasm_state != 'archived_state'"
  has_and_belongs_to_many :procedures
  has_and_belongs_to_many :properties

  has_many :development_teams
  has_many :teams, through: :development_teams
  has_many :groups, through: :teams


  has_many :apps_business_processes, :dependent => :destroy
  has_many :business_processes, :order => "business_processes.name", :through => :apps_business_processes
  has_many :active_business_processes, through: :apps_business_processes,
           source: :business_process, conditions: { archived_at: nil }

  has_many :assigned_apps, :dependent => :destroy

  has_many :users, :through => :assigned_apps
  has_many :team_users, source: :users, through: :teams

  has_many :component_templates, :dependent => :destroy
  has_many :package_templates,   :order => 'name ASC', :dependent => :destroy

  has_many :active_packages, through: :application_packages, source: :package, conditions: { active: true }

  has_many :steps
  has_many :tickets

  concerned_with :app_named_scopes
  concerned_with :import_export

  #routes are per application collections of environments in serial or parallel groups used by plans for promotions
  has_many :routes, :dependent => :destroy
  has_many :active_routes, class_name: Route, conditions: "routes.name != '[default]' AND routes.archived_at IS NULL"
  has_many :route_gates, :through => :routes

  before_validation :find_user
  after_create :give_access_to_creator, :create_default_route, :give_access_to_teams
  after_save :set_environments, :set_components, :set_packages

  validates :name,
    presence: true,
    uniqueness: {case_sensitive: false},
    length: {maximum: 255}

  validates :app_version,
    length: {in: (1..100), unless: Proc.new { |a| a.app_version.blank? }}

  validate :lookups_succeeded

  normalize_attributes :name

  attr_accessible :environment_ids, :user_ids, :name, :app_version, :active,
    :default, :strict_plan_control, :a_sorting_envs, :a_sorting_comps,
    :team_ids

  attr_reader :new_package_ids
  attr_accessor :user_lookup_failed, :user_ids

  scope :default_app, where(id: DEFAULT_APP_ID)

  acts_as_audited protect: false

  def team_names
    teams.map(&:name).to_sentence
  end

  def active_package_templates
    package_templates.active
  end

  def inactive_package_templates
    package_templates.inactive
  end

  def is_accessible_to?(user)
    user.admin? || !user.assigned_apps.where(:app_id => id).select(:app_id).blank?
  end

  # a convenience method to return the default route for an app instance
  def default_route
    Route.default_route_for_app_id(self.id)
  end

  def environment_ids=(new_ids)
    @new_environment_ids = new_ids.uniq.map(&:to_i)
    @environments_set = true
  end

  def component_ids=(new_ids)
    @new_component_ids = new_ids.map(&:to_i)
    @components_set = true
  end

  def package_ids=(new_ids)
    @new_package_ids = new_ids.map(&:to_i)
  end

  def alpha_sort_envs
    ApplicationEnvironment.transaction do
      environments.active.reorder('lower(name) ASC').each_with_index do |env, i|
        self.application_environments.find_by_environment_id(env.id).update_attributes(position: i+1, different_level_from_previous: true)
      end
    end
  end

  def alpha_sort_comps
    ApplicationComponent.transaction do
      components.active.reorder('lower(name) ASC').each_with_index do |comp, i|
        self.application_components.find_by_component_id(comp.id).update_attributes(position: i+1, different_level_from_previous: true)
      end
    end
  end

  def servers_with_installed_components
    #environments.map { |env| env.servers }.flatten.uniq.select { |server| server.has_components_on_app? self }
    ret_servers = []
    self.installed_components.each do  |installed_component|
      ret_servers = ret_servers + installed_component.physical_server_associations
    end
    ret_servers.uniq
  end

  def clone_new_app(new_app_name, proj_id_for_unshared_infrastructure = false)
    return nil if new_app_name.blank?

    new_app = clone
    new_app.name = new_app_name
    new_app.default = false

    new_app.save!
    ids_hash = { Environment => Hash.new { |h, k| k }, Component => Hash.new { |h, k| k } }
    if proj_id_for_unshared_infrastructure

      clone_and_rename = proc { |dom|
        copy = dom.dup
        copy.name = "#{proj_id_for_unshared_infrastructure}.#{copy.name}"
        copy.default = false if copy.respond_to?(:default=)
        copy.save!
        ids_hash[dom.class][dom.id] = copy.id
        copy
      }

      new_app.environments = environments.map(&clone_and_rename)
      #new_app.components = components.map(&clone_and_rename)
      new_app.components = components
    else
      new_app.environments = environments
      new_app.components = components
    end

    installed_components.each do |installed_component|
      app_env = new_app.application_environments.find_by_environment_id(ids_hash[Environment][installed_component.environment_id])
      app_comp = new_app.application_components.find_by_component_id(ids_hash[Component][installed_component.component_id])
      InstalledComponent.create!(:application_environment_id => app_env.id, :application_component_id => app_comp.id)
    end

    new_app
  end

  def add_remote_components(application_environment_ids_to_update, referenced_installed_component_ids)
    err_msgs = []
    referenced_installed_component_ids.each do |installed_component_id|
      referenced_installed_component = InstalledComponent.find(installed_component_id)
      new_component = referenced_installed_component.component

      #User.current_user.log_activity(:context => "Component #{new_component.try(:name)} added to Application #{name}") do
        new_component.update_attribute(:updated_at, new_component.updated_at)
        self.components << new_component unless self.components.include? new_component
      #end

      application_environment_ids_to_update.each do |application_environment_id|
        if application_environment_id.include?("_")
          application_environment_id = application_environment_id.split("_").first
        end
        application_component = self.application_components.find_by_component_id(new_component.id)
        installed_comp = InstalledComponent.create(
          application_environment_id: application_environment_id,
          application_component: application_component,
          reference: referenced_installed_component
        )
        if installed_comp.errors.present?
          application_environment = ApplicationEnvironment.find(application_environment_id)
          err_msgs << "#{application_component.component.name} is already added to #{application_environment.environment.name}."
        end
      end
    end
    err_msgs
  end

  def each_component_level
    rval_components = []
    level = 1

    self.application_components.each do |component|
      if component.different_level_from_previous?
        unless rval_components.empty?
          yield(rval_components, level)
          level += 1
        end
        rval_components = [component]
      else
        rval_components << component
      end
    end

    yield(rval_components, level)
  end

  def each_environment_level
    rval_environments = []
    level = 1

    self.application_environments.each do |environment|
      if environment.different_level_from_previous?
        unless rval_environments.empty?
          yield(rval_environments, level)
          level += 1
        end
        rval_environments = [environment]
      else
        rval_environments << environment
      end
    end

    yield(rval_environments, level)
  end

  def copy_components_across_environments(app_components, to_app_envs, keep_old=false)
    old_ics = keep_old ? InstalledComponent.all(
      :conditions => {:application_component_id => app_components.map{|c| c.id },
        :application_environment_id => to_app_envs.map{|e| e.id} }) : []
    to_app_envs.each{|to_app_env| to_app_env.installed_components.destroy_all } unless keep_old

    app_components.each do |component|
      to_app_envs.each do |environment|
        unless old_ics.any?{|old| old.application_component == component && old.application_environment == environment }
          InstalledComponent.create!(:application_component => component, :application_environment => environment)
        end
      end
    end
  end

  def copy_all_components_to_all_environments
    app_environments = application_environments
    copy_components_across_environments(application_components, app_environments, true)
  end

  def environments_visible_to_user(user = User.current_user)
    envs = environments.active.reorder('environments.name ASC').uniq
    envs = envs.joins(:assigned_apps)
               .where(:'assigned_apps.app_id' => self.id)
               .where(:'assigned_apps.user_id' => user.id) unless user.root?
    envs
  end

  def app_environments_visible_to_user(user = nil)
    user = user.blank? ? User.current_user : user
    conditions = {}
    conditions["assigned_apps.user_id"] = user.id unless user.admin?
    application_environments.
      joins(:assigned_apps).joins(:environment).
      where(conditions).reorder("environments.name ASC").all.uniq
  end


  def accessible_environments_from(accessible_environments)
    if accessible_environments.blank?
      []
    else
      env_id = accessible_environments.map(&:id)
      env_id ? Environment.find(env_id) : []
    end
  end

  def installed_components_for_env(environment_id)
    InstalledComponent.without_finding_server_ids {
      self.environment_components.where('application_environments.environment_id = ?', environment_id).
          includes(application_component: :component).all
    }
  end

  def default?
    id == DEFAULT_APP_ID
  end

  def have_at_least_one_group
    groups.size > 0
  end

  def app_package_for_package_id( package_id )
    application_packages.where( package_id: package_id ).first
  end

  def requests_for_export_with_automations
    select_requests_for_export.as_json(RequestExportOptions.new(true).options)
  end

  def requests_for_export
    select_requests_for_export.as_json(RequestExportOptions.new(false).options)
  end

  private

  def select_requests_for_export
    requests.select { |request| request.is_exportable?(request)  }
  end

  # convenience finder (mostly for REST clients) that allows you to pass an app_name
  # and an environment name and have us locate the application environment
  def find_user
    self.user_lookup_failed = false
    unless self.user_ids.blank?
      my_users = User.scoped.extending(QueryHelper::WhereIn).where_in('id', self.user_ids)
    unless my_users.blank?
        self.users = my_users
      else
        self.user_lookup_failed = true
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  # The team needs assignment create
  def give_access_to_teams
    teams.includes(:users).each do |team|
      team.users.each do |user|
        user.set_access_to_app(self, team.id)
      end
    end
  end

  # If user creates an application he gets DIRECT ACCESS to app
  def give_access_to_creator
    user = User.current_user
    unless user.blank?
      user_assignment = user.assigned_apps.where(app_id: self.id) rescue nil
      if user_assignment.blank?
        user.assigned_apps.create!(app_id: self.id)
        PermissionMap.instance.clean(user)
      end
    end
  end

  # create the default route
  def create_default_route
    Route.default_route_for_app_id(self.id) if self.id.present?
  end

  def set_environments
    if @environments_set
      env_ids = self.environment_ids - @new_environment_ids
      self.application_environments.find_all_by_environment_id(env_ids).map(&:destroy)
      env_ids.each do |environment_id|
        environment = Environment.find environment_id
        env_link = environment_link(environment)
      end

      (@new_environment_ids - self.environment_ids).each do |environment_id|
        if Environment.exists?(environment_id)
          self.application_environments.create(environment_id: environment_id)
        end
      end
    end
  end

 def lookups_succeeded
    self.errors.add(:user, "could not be found. Check that the login id is valid.") if self.user_lookup_failed
  end

  def set_components
    if @components_set
      comp_ids = self.component_ids - @new_component_ids
      self.application_components.find_all_by_component_id(comp_ids).map(&:destroy)

      comp_ids.each do |component_id|
        component = Component.find component_id
        #User.current_user.log_activity(:context => "Component #{component.try(:name)} removed from Application #{name}") do
          component.update_attribute(:updated_at, component.updated_at)
        #end
      end

      #      (@new_component_ids - self.component_ids).each do |component_id|
      #        self.application_components.create(:component_id => component_id)
      #      end
    end
  end

  def set_packages
    unless new_package_ids.nil?
      remove_packages
      associate_packages
    end
  end

  def remove_packages
    del_package_ids = self.package_ids - new_package_ids
    self.application_packages.find_all_by_package_id(del_package_ids).map(&:destroy)
  end

  def associate_packages
    ids_to_associate = new_package_ids - self.package_ids
    ids_to_associate.each do |package_id|
      associate_package(package_id)
    end
  end

  def associate_package(package_id)
    package = Package.find package_id
    package.update_attribute(:updated_at, package.updated_at)
    self.application_packages.create(package_id: package_id)
  end
end
