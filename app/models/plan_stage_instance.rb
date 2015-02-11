################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################


class PlanStageInstance < ActiveRecord::Base
  include ArchivableModelHelpers
  include FilterExt

  # concerned with mix-in for aasm statemachine
  concerned_with :plan_stage_instance_state_machine

  attr_accessible :aasm_state, :archive_number, :archived_at, :plan_id, :plan_stage_id

  belongs_to :plan
  belongs_to :plan_stage

  # an association that allows plan stage instances to be governed by constraints such
  # as route gates, environmental windows, and plan stage dates
  has_many :constraints, :as => :governable, :dependent => :destroy

  validates :plan_id, :plan_stage_id, :presence => true
  validates :plan_id, :plan_stage_id, :numericality => {:only_integer => true}
  validates :plan_stage_id, :uniqueness => {:scope => :plan_id}

  scope :filter_by_plan_id, lambda { |filter_value| where(:plan_id => filter_value) }
  scope :filter_by_plan_stage_id, lambda { |filter_value| where(:plan_stage_id => filter_value) }

  scope :in_plan_stage_position_order, joins(:plan_stage).order('plan_stages.position ASC')

  # may be filtered through REST
  is_filtered cumulative: [:plan_id, :plan_stage_id], boolean_flags: {default: :unarchived, opposite: :archived}

  # before deletion, archive the model since we have no real gui for archiving, but want to follow
  # the lifecycle routine of archiving when parent models are archives and allow archiving by secondary objects
  before_destroy :archive

  # delegate some properties to plan_stages
  delegate :environment_type, :to => :plan_stage, :prefix => false, :allow_nil => true
  delegate :name, :to => :plan_stage, :prefix => true, :allow_nil => true
  delegate :position, :to => :plan_stage, :prefix => true, :allow_nil => true

  def strict?
    plan_stage.try(:strict?)
  end

  def can_be_archived?
    true # allows archiving unless there is a reason not to
  end

  def can_be_destroyed?
    true # allow it to be destroyed, but archive it as part of the process
  end

  # convenience method for retrieving plan stage requests, associated indirectly for historical reasons
  # through plan, plan_stage, and plan_member.  If done from scratch, plan stage instance would have been
  # the link between plan_member and a particular plan_stage, though some provision needs to be made
  # for requests unassigned to a particular stage
  def requests
    Request.by_plan_id_and_plan_stage_id(plan_id, plan_stage_id)
  end

  # this method is called by the constraint validation for each model
  # that is governable, and expects a message returned to determine whether
  # the proposed match betweeen a governable object and a constraint
  # is valid and what to display if it is not
  def can_be_constrained_by(constrainable)
    # start by testing if it is the right kind of object
    case constrainable.class.to_s
      when 'RouteGate'
        # enforce environment type matching if the environment is strict
        if strict? && !valid_route_gate(constrainable)
          "plan stage instance of STRICT environment type #{ environment_type.try(:name) } cannot be constrained by a #{constrainable.class.to_s} of environment type #{ constrainable.try(:environment_type).try(:name) || 'None' }"
        else
          ''
        end
      else
        "plan stage instance cannot be constrained by a #{constrainable.class.to_s}"
    end
  end

  # a grouped array of constraint totals by type
  def constraints_by_type
    constraints.order('constrainable_type ASC').group_by(&:constrainable_type)
  end

  # a standard constrain validation routine to check if a governable object
  # is valid according to its constraints and takes actions
  # returns a validation object with messages
  def constraint_violations
    policy_outcomes = []
    # run through the constraints by type and apply the right policy
    # and accumulate message objects
    if !valid_for_promotion?
      policy_outcomes << promotion_restriction_messages
    else
      constraints_by_type.each do |type, constraints|
        case type
          when 'RouteGate'
            policy_outcomes << RouteGatePolicy.new(self, constraints).validate
          else
            logger.error("Constraint Validation Error: Unsupported constrainable_type #{type}.")
            policy_outcomes << ConstraintValidationOutcome.new(self, nil, false,
                                                           "Constrainable model of type #{type} is not supported.")
        end
      end
    end

    # get rid of spurious empty arrays
    policy_outcomes.flatten!

    # act on the policy_outcomes
    if policy_outcomes.present?
      mark_noncompliant! unless noncompliant?
    else
      mark_compliant! unless compliant?
    end


    return policy_outcomes
  end

# add archiving to the destroy step
  def destroy
    archive
    super
  end


# when a plan is associated with a route -- creation of plan_route -- then
# we need to remove old constraints and add new ones
  def create_constraints_for_route_id(route_id)
    success = true
    route_gates = RouteGate.filter_by_route_id(route_id)

    success = destroy_constraints_for_route_id(route_id) unless constraints.blank?
    success = make_constraints_for_route_id(route_id, route_gates) unless route_gates.blank?

    return success

  end

  # Checks constraints to see if this is a compliant item -- can be expanded to cover other
  # types of items and should return either RouteGatePolicy value objects or nil if no
  # actionable errors.
  def compliance_issues_for_item(item)
    issues = []

    if constraints_by_type.present?
      case item.class.name
        when 'Request'
          # this uses the single item checker in the RouteGate policy and returns true or false
          issues << RouteGatePolicy.new(self, constraints_by_type['RouteGate']).validate_item(item)
        else
          logger.error("Unsupported item passed to plan stage instance for validation: #{ item.try(:class).try(:name) || 'Nil' }")
          nil
      end
      issues.compact!
    elsif !valid_for_requests?
      issues << RouteGatePolicy.new(self, nil).validate_item(item)
    else
      nil
    end

    return issues
  end

  # Convenience method to provide a list of environments legal for an app and a stage
  def allowable_environments_for_request(request)
    route_gate_policy = RouteGatePolicy.new(self, constraints_by_type['RouteGate'])
    route_gate_policy.policy_compliant_values_for_item(request)
  end

  # check whether PSI valid for requests in there are no constrans
  # not the most semantic method name
  def valid_for_requests?
    return true if plan.routes.none?
    constraints.any?
  end

  def valid_for_promotion?
    valid_for_requests? && gates_without_constraints_messages.blank?
  end

  def gates_without_constraints_messages
    without_constraints_messages = []
    plan.plan_routes.each do |plan_route|
      if constraints.filter_by_route_id(plan_route.route.id).blank?
        message = ConstraintValidationOutcome.new(self, nil, false, I18n.translate(:no_route_gates_for_app, app_name: plan_route.route.app_name))
        without_constraints_messages << message
      end
    end
    without_constraints_messages
  end

  def promotion_restriction_messages
    messages = []
    if constraints.blank?
      messages << ConstraintValidationOutcome.new(self, nil, false, I18n.translate(:no_route_gates_available))
    elsif gates_without_constraints_messages.present?
      messages << gates_without_constraints_messages
    end
    messages << RouteGatePolicy.new(self, constraints).validate
  end

  private

# clears constraints related to a particular route
  def destroy_constraints_for_route_id(route_id)
    # pull each instance's existing constraints
    constraints.filter_by_route_id(route_id).try(:destroy_all)

    # consider reasons why this might return false?
    true
  end

# makes constraints for the route id
  def make_constraints_for_route_id(route_id, route_gates)
    success = true
    # check if the route was located and if it has route_gates
    if route_gates.present?
      # cycle through the route_gates and assign them as constraints by environment type
      route_gates.each do |rg|
        # check if it meets conditions for assignment
        if valid_route_gate(rg)
          # double check if a constraint exists
          constraint = self.constraints.filter_by_constraint({id: rg.id, type: 'RouteGate'})
          # create one if it does not, consider trapping errors if any
          constraints.create(constrainable_id: rg.id, constrainable_type: 'RouteGate') unless constraint.present?
        end
      end
      success = true
    end

    return success
  end

# test for whether this route gate can be assigned here by default
  def valid_route_gate(route_gate)
    # at the moment we test for matching environment types between the plan_stage and the environment
    # contained in the route_gate, but soon we will be adding other allowable entries
    self.environment_type == route_gate.try(:environment_type)
  end

  # return the unique attributes that test pass or fail as a constraint
  def constrainable_filter_value(constrainable)
    {app_id: constrainable.route_app_id, environment_id: constrainable.environment_id}
  end

end
