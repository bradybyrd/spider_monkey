################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PlanRoute < ActiveRecord::Base
  include FilterExt

  attr_accessible :plan_id, :route_id, :plan, :route

  belongs_to :plan
  belongs_to :route

  has_many :route_gates, through: :route

  validates :plan_id, :route_id, :presence => true
  validates :plan_id, :route_id, :numericality => {:only_integer => true}
  validates :route_id, :uniqueness => {:scope => :plan_id}

  # we need a special validation to check if the application has
  # already been routed for this plan
  validate :app_uniqueness_in_plan

  scope :filter_by_plan_id, lambda { |filter_value| where(:plan_id => filter_value) }
  scope :filter_by_route_id, lambda { |filter_value| where(:route_id => filter_value) }
  scope :filter_by_app_id, lambda { |filter_value| joins(:route).where('routes.app_id' => filter_value) }

  scope :in_route_name_order, joins(:route).order('LOWER(routes.name) ASC')
  scope :in_app_name_order, joins(:route => :app).order('LOWER(apps.name) ASC, LOWER(routes.name) ASC')

  # when a plan_route is created or updated, we should run through and create or correct
  # the constraints for that plans plan_stage_instances
  after_save :create_or_update_constraints

  # delegate common attributes to associations
  delegate :name, to: :route, prefix: true, allow_nil: true
  delegate :app_name, to: :route, prefix: true, allow_nil: true
  delegate :environments_list, to: :route, prefix: true, allow_nil: true
  delegate :app_id, to: :route, prefix: true, allow_nil: true
  delegate :app, to: :route, prefix: true, allow_nil: true
  delegate :name, to: :plan, prefix: true, allow_nil: true

  # may be filtered through REST
  is_filtered cumulative: [:plan_id, :route_id, :app_id],
              default_flag: :all

  # convenience method for other active plans
  def other_active_plans_list
    list = route.other_active_plans_list(plan)
    list.blank? ? 'None' : list
  end

  def unassigned_route_gates
    assigned_route_gate_ids = plan.constraints.filter_by_constrainable_type('RouteGate').map(&:constrainable_id)
    route.route_gates.where('id NOT IN (?)', assigned_route_gate_ids) || []
  end

  private

  # when a plan route is created or updated, we need to remove previous constraints
  # associated with the plan_route and reapply the current set
  def create_or_update_constraints
    # find current plan_stage_instances
    plan.plan_stage_instances.each do |psi|
      # tell the instance to remove old constraints and add new ones
      psi.create_constraints_for_route_id(route_id)
    end
    return true
  end

  # an app can only have one route per plan
  def app_uniqueness_in_plan
    # check for plan_routes plans for this app and plan
    if PlanRoute.filter_by_plan_id(plan_id).filter_by_app_id(route_app_id).any?
      errors.add(:route_id, 'for app already assigned to plan')
    end
  end
end