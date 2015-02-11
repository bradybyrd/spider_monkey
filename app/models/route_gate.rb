################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class RouteGate < ActiveRecord::Base
  include FilterExt

  attr_accessible :description, :different_level_from_previous, :environment_id, :position, :route_id, :insertion_point,
                  :route, :environment

  validates :description, length: {maximum: 255}
  validates :environment_id, uniqueness: {scope: :route_id}

  normalize_attribute :description

  belongs_to :route
  belongs_to :environment

  # a polymorphic relationship with plan_stages to act as a type of constraint on their contents
  has_many :constraints, as: :constrainable, dependent: :destroy

  # make a list with position column unless archived
  acts_as_list :scope => [:route_id, :archived_at]

  # delegate some properties to environments
  delegate :environment_type, to: :environment, prefix: false, allow_nil: true
  delegate :full_label, to: :environment, prefix: false, allow_nil: true
  delegate :app, to: :route, prefix: true, allow_nil: true
  delegate :app_id, to: :route, prefix: true, allow_nil: true

  scope :in_order, order('position')

  scope :filter_by_environment_id, lambda { |filter_value| where(:environment_id => filter_value) }
  scope :filter_by_route_id, lambda { |filter_value| where(:route_id => filter_value) }

  # check if the route gate can be deleted
  before_destroy :can_be_deleted?

  # may be filtered through REST
  is_filtered cumulative: [:environment_id, :route_id], default_flag: :all

  def insertion_point
    position
  end

  # constrainable api benefits from a label function so it can get all the
  # unique information needed to understand the purpose of a constraint and,
  # for example, display that information in a pop-up table for users
  def constrainable_label
    "#{ route.try(:app).try(:name) } : #{ route.try(:name) } : #{ environment.try(:name) }"
  end

  def full_label
    environment.try(:full_label)
  end

  def strict?
    environment_type.try(:strict)
  end

  def eligible_plan_stage_instances_for_plan_id(plan_id)
    # get the plan stage instances for the passed plan
    plan_stage_instances = PlanStageInstance.filter_by_plan_id(plan_id).all
    # if there are others, reject any that don't meet our rules
    if plan_stage_instances.present?
      # if either one of these are strict, enforce matching environment types
      plan_stage_instances.reject! do |psi|
        ((psi.strict? || self.environment_type.try(:strict)) && (psi.environment_type != self.environment_type)) || psi.plan_stage.blank?
      end

      # if there is already a route gate among its constraints, reject it
      plan_stage_instances.reject! { |psi| psi.constraints.filter_by_constraint({id: self.id, type: 'RouteGate'}).try(:any?) }
    end
    plan_stage_instances
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end

# only archive if there are no related plan stages or environments
  def can_be_deleted?
    # Add a binding that prevents deleting with an active plan
    self.try(:route).try(:plans).try(:blank?)
  end

end
