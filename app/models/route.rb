################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Route < ActiveRecord::Base
  include FilterExt

  # posit a constant defining allowable route types
  ROUTE_TYPES = %w(open mixed strict)

  # default route explanatory message
  DEFAULT_ROUTE_DESCRIPTION = 'The default route for an application includes all environments and cannot be modified directly.'

  attr_accessible :app_id, :description, :name, :route_type, :app, :route_gates, :route_gate_ids, :plan_route_ids, :new_environment_ids

  # a virtual attribute for conveniently associating selected environments with a route, creating route gates with sensible defaults
  attr_accessor :new_environment_ids
  validate :valid_environment_ids
  before_update :assign_new_environment_ids

  validates :name, :presence => true, :uniqueness => {:scope => :app_id}, :length => {:minimum => 2, :maximum => 255}
  validates :description, :length => {:maximum => 255}
  validates :route_type, :inclusion => {:in => ROUTE_TYPES}
  validate :do_not_modify_default_route


  normalize_attribute :name, :description

  has_many :route_gates, :dependent => :destroy, :order => :position
  has_many :environments, :through => :route_gates
  has_many :plan_routes, :dependent => :destroy
  has_many :plans, :through => :plan_routes

  belongs_to :app

  delegate :name, to: :app, prefix: true, allow_nil: true
  delegate :id, to: :app, prefix: true, allow_nil: true


  # make archivable
  include ArchivableModelHelpers

  def destroyable?
    can_be_archived? && self.archived? && self.plans.none?{|plan| plan.archived?}
  end

  # this shoud be case sensitive as some people use development and Development as meaningful types
  scope :filter_by_name, lambda { |filter_value| where(:name => filter_value) }
  scope :filter_by_app_id, lambda { |filter_value| where(:app_id => filter_value) }
  scope :filter_by_environment_id, lambda { |filter_value| joins(:route_gates).where('route_gates.environment_id' => filter_value) }
  scope :filter_by_route_type, lambda { |filter_value| where(:route_type => filter_value) }

  # a scope to help us exclude the default for rules like applicaton environment removal
  # which can happen with just the default route, but not with any hand made routes
  scope :not_default, where("name != '[default]'")

  # convenient ordering scopes
  scope :in_name_order, order('routes.name ASC')

  # may be filtered through REST
  is_filtered cumulative: [:name, :app_id, :route_type],
              boolean_flags: {default: :unarchived, opposite: :archived}


  # a class method for finding and or creating a default Route for an app
  # that includes all of its current application environments
  # thereafter post_commit hooks on the application_environment
  # model will manage the sychronization of this default route.
  def self.default_route_for_app_id(passed_app_id)
    # retrieve the application
    app = App.find(passed_app_id)

    # see if the default exists already or create it
    default_route = create_default_route_and_gates(app)

    # run some sanity tests
    if default_route.route_gates.count != app.environments.count
      synchronize_default_route_gates_count(default_route)
    end

    # make sure the description matches
    sychronize_default_route_description(default_route)

    return default_route
  end

  # create default route and populate its gates for application
  def self.create_default_route_and_gates(app)
    default_route = self.where(:name => '[default]', :app_id => app.id).try(:first)
    if default_route.blank?
      default_route = Route.create(name: '[default]',
                                   app_id: app.id,
                                   description: DEFAULT_ROUTE_DESCRIPTION)
      app.application_environments.each do |ae|
        default_route.route_gates.create(environment_id: ae.environment_id, position: ae.position, different_level_from_previous: ae.different_level_from_previous)
      end
    end
    return default_route
  end

  # synchronize default route gates number
  def self.synchronize_default_route_gates_count(default_route)
    # try to reconcile the two
    default_route.app.application_environments.each do |ae|
      route_gate = default_route.route_gates.find_or_create_by_environment_id(ae.environment_id)
      # sychronize the positions
      route_gate.insertion_point = ae.position
      route_gate.update_attributes(different_level_from_previous: ae.different_level_from_previous)
    end
  end

  # sychronize default route description
  def self.sychronize_default_route_description(default_route)
    # make sure the description matches
    if default_route.description != DEFAULT_ROUTE_DESCRIPTION
      default_route.update_attributes(description: DEFAULT_ROUTE_DESCRIPTION)
    end
  end

  # convenience method for determining if this is a default route
  # at the moment this is a simple name check but it could be a
  # more intensive check that its contents are synchronized with
  # the application environments if needed
  def default?
    name == '[default]'
  end

  # convenience method for the name of a route in a select menu
  def name_for_select
    name.try(:truncate, 25)
  end
  def name_with_app
    label = []
    label << app.try(:name).try(:truncate, 30) if app
    label << name.try(:truncate, 30)
    label.join(': ')
  end

  # only archive if there are no running plans
  def can_be_archived?
    # prevent archiving with a running plan and not the default
    self.active_plans.empty? && !default?
  end

  # only allow deletion if it is archived and has no plans at all, running or not and not the default
  def can_be_deleted?
    self.archived? && self.plans.empty?  && !default?
  end

  # a convenience function to provide an environments list
  def environments_list
    if self.route_gates.present?
      self.route_gates.map { |r| r.try(:environment).try(:name) }.compact.to_sentence
    else
      'None'
    end
  end

  # convenience method to format other active plans like a list
  def other_active_plans_list(plan)
    plans = other_active_plans(plan)
    if plans.present?
      plans.map(&:name).compact.to_sentence
    else
      'None'
    end
  end

  # convenience method to format other active plans like a list
  def active_plans_list(archived_plans = nil)
    plans = active_plans

    result = if plans.present?
      plans.map(&:name).compact.to_sentence
    else
      'None'
    end

    result += ' / ' + if archived_plans.present?
      archived_plans.map(&:name).compact.to_sentence
    else
      'None'
    end

  end

  # convenience method to report active plans other than the one
  # passed to the method
  def other_active_plans(plan)
    active_plans.not_including_id(plan.id) || []
  end

  # convenience method to show plans that are active
  def active_plans
    @active_plans ||= plans.running.sorted || []
  end

  # ordering of route gates is a mix of position and different_level_from_previous
  # this method sorts the route_gates into banded levels for the reorder screen
  # returning an array like [ [[route1, route2], 1], [[route3], 2] ]
  def each_route_gate_level
    rval_route_gates = []
    level = 1

    self.route_gates.each do |route_gate|
      if route_gate.different_level_from_previous?
        unless rval_route_gates.empty?
          yield(rval_route_gates, level)
          level += 1
        end
        rval_route_gates = [route_gate]
      else
        rval_route_gates << route_gate
      end
    end

    yield(rval_route_gates, level)
  end

  # when a route is added to a plan through a plan_route, we pass the plan_id
  # back to the route (which knows about its gates) for creation or updating of
  # the appropriate constraints
  def create_or_update_constraints(plan_id)
    # cycle through the route_gates and tell them up update or remove constraints
    route_gates.each do |rg|
      rg.create_or_update_constraints(plan_id)
    end
  end

  private


  # validation for environment ids to make sure the values are sane and exist
  def valid_environment_ids
    # make sure it is not empty
    unless self.new_environment_ids.blank?
      # drop any duplicates right away to avoid bringing them back
      self.new_environment_ids = self.new_environment_ids - self.environment_ids
      # test again for blank?
      unless self.new_environment_ids.blank?
        # we only need ids so save a little network traffic by selecting just its
        @pending_environments = self.app.environments.select('environments.id').where(:id => self.new_environment_ids)
        # make sure they all point to valid environment_ids for the app
        unless @pending_environments.count == self.new_environment_ids.count
          self.errors.add(:new_environment_ids, "Some environment ids were invalid for this application. Reload and try again?")
        end
      end
    end
  end

  # the assignment function for the new_environment_ids helper that stamps out route gates
  # ignoring existing environments, dropping duplicates, and always adding new ones
  # reuse the instance variable from the validation to avoid another database call
  def assign_new_environment_ids
    # make sure it is not empty
    unless @pending_environments.blank?
      # cycle through the environments and make a stage gate for each at the bottom
      @pending_environments.each do |environment|
        self.route_gates.create(:environment => environment)
      end
    end
  end

  def do_not_modify_default_route
    errors.add(:name, 'is [default]. This system route cannot be modified.') if default? && !new_record?
  end

end
