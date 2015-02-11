################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class ApplicationEnvironment < ActiveRecord::Base

  attr_accessible :app_id, :user_id, :position, :different_level_from_previous, :environment_group_id, :version_tag_id, :insertion_point, :environment_id

  belongs_to :app
  belongs_to :environment
  has_many  :installed_components, :dependent => :destroy, :include => :application_component, :order => 'application_components.position'
  has_many  :application_components, :through => :installed_components, :order => 'application_components.position'
  has_many  :version_tags,  :foreign_key => 'app_env_id'
  has_many  :components, through: :application_components
  has_many  :assigned_apps, :foreign_key => :app_id, :primary_key => :app_id
  has_one   :team_group_app_env_role

#  has_many :assigned_evironments, :class_name => "AssignedEnvironment", :finder_sql =>
#    'SELECT assigned_environments.* FROM assigned_environments ' +
#    'INNER JOIN assigned_apps ON assigned_apps.id = assigned_environments.assigned_app_id ' +
#    'WHERE assigned_apps.app_id = #{app_id} AND ' +
#    'assigned_environments.environment_id = #{environment_id} '

  validates :app,
            :presence => true
  validates :environment,
            :presence => true
  validates :app_id,
            :presence => true,
            :uniqueness => {:scope => [:app_id, :environment_id]}

  delegate :name, :to => :environment, :allow_nil => true
  delegate :environment_type, :to => :environment, :allow_nil => true

  before_destroy :check_if_environment_can_be_removed_from_app

  after_save :synchronize_default_route
  after_destroy :remove_route_gates

  acts_as_list :scope => :app

  scope :in_order, order('application_environments.position')

  # with_installed_components & having_installed_components does same work but latter is more efficient
  # include is always better than joins
  # TODO - Discuss with Piyush and make changes everywhere

  scope :with_installed_components, includes(:installed_components).where('installed_components.application_environment_id = application_environments.id')
  scope :having_installed_components, joins("INNER JOIN installed_components ON application_environments.id = installed_components.application_environment_id")

  scope :having_environment_ids, lambda { |environment_ids|
    where("application_environments.environment_id" => environment_ids)
  }

  scope :by_application_and_environment_names, lambda { |application_name, environment_name|
    {
      :include => [:app, :environment],
      :conditions => ["(apps.name LIKE ? OR apps.name LIKE ?) AND environments.name LIKE ?", application_name, "#{application_name}_|%", environment_name]
    }
  }

  scope :id_equals, lambda{ |ids|
    where("application_environments.id" => ids)
  }

  def self.acccessible_to_user(user)
    conditions = if user.has_global_access?
      "assigned_apps.user_id IS NOT NULL"
    else
      "assigned_apps.user_id = #{user.id}"
    end

    joins("INNER JOIN assigned_apps ON assigned_apps.app_id = application_environments.app_id ").where(conditions).
    group(ApplicationEnvironment.column_names.collect{|c| "application_environments.#{c}" }.join(", "))
  end

  scope :for_plan, lambda { |plan_id|
    select("distinct application_environments.*").
    joins("INNER JOIN apps_requests ON application_environments.app_id = apps_requests.app_id
        INNER JOIN environments ON application_environments.environment_id = environments.id
        INNER JOIN requests ON apps_requests.request_id = requests.id
        INNER JOIN plan_members ON requests.plan_member_id = plan_members.id AND environments.id = requests.environment_id").
    where("plan_members.plan_id" => plan_id).
    group(ApplicationEnvironment.column_names.collect{|c| "application_environments.#{c}" }.join(", "))
  }

  class << self

    def associate_defaults
      default_app = App.find_or_create_default
      default_environment = Environment.find_or_create_default

      find_or_create_by_app_id_and_environment_id(default_app.id, default_environment.id)
    end

  end

  def name_label
    self.name
  end

  def insertion_point
    self.position
  end

  def insertion_point=(new_position)
    self.insert_at(new_position.to_i)
  end

  def installed_component_for(given_component)
    self.installed_components.first(:include => [:application_component], :conditions => ['application_components.component_id = ?', given_component.id])
  end

  protected

  # when an environment is no longer assigned to an application, we should remove it from any route gates
  def remove_route_gates
    # see if there are any routes for this application
    routes = Route.filter_by_app_id(app_id)
    # iterate through them, if any, and remove the route gates
    routes.each do |route|
      # find any route gates for this environment and app
      route_gates = route.route_gates.filter_by_environment_id(environment_id)
      # destroy them if found
      route_gates.destroy_all if route_gates.present?
    end
  end

  # before we destroy this association, test if we can remove the environment from the app
  def check_if_environment_can_be_removed_from_app
    environment.can_be_removed_from_app?(app)
  end

  # whenever something changes with an application environment, we need to
  # synchronize a special default route with it
  def synchronize_default_route

    # search for the default route an initialize it if it is not there
    default_route = Route.default_route_for_app_id(app_id)

    # find or create a matching route gate
    route_gate = default_route.route_gates.find_or_create_by_environment_id(self.environment_id)

    route_gate.insertion_point = self.position

    route_gate.update_attributes(different_level_from_previous: self.different_level_from_previous)
  end

end
