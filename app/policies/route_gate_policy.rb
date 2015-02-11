################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

class RouteGatePolicy

  # once initialized, outside code should not really be changing those values
  attr_reader :governable, :constraints

  def initialize(governable, constraints)
    @governable = governable
    @constraints = constraints
  end

  # does the governed object pass the constraint
  def validate
    results = []
    results << case
                 when !governable_supported?
                   ConstraintValidationOutcome.new(governable, nil, false, "Route Gate policy cannot be applied to objects of type #{ governable.class.name }")
                 when !constrainable_supported?
                   ConstraintValidationOutcome.new(governable, nil, false, "Route Gate policy cannot enforce constraints of type #{ illegal_constrainable_types.to_sentence }")
                 # first check if a gross error has occurred and there is a bad environment type match
                 when !strict_respected?
                   ConstraintValidationOutcome.new(governable, nil, false, 'Governable and constrainable environment types must match if one is strict')
                 else
                   # if nothing seems insane about the governable and constraint situation
                   # now check if the plan stage instance has all matching request environments
                   validate_contents
               end
    results.flatten
  end

  def validate_contents
    results = []
    governable.requests.each do |request|
      results << validate_item(request)
    end
    results.compact
  end

  def validate_item(request)
    test_value = [request.app_ids.try(:first), request.environment.try(:id)]
    if policy_compliant_values.include?(test_value)
      nil
    else
      ConstraintValidationOutcome.new(governable, request, false, error_message_for_item(request))
    end
  end

  # a helper to provide legal alternatives when validation fails
  def policy_compliant_value_labels_for_item(request)
    labels = policy_compliant_values_for_item(request).map(&:name)
    if labels.present?
      labels.to_sentence
    else
      'None'
    end
  end

  # a helper to provide legal alternatives when validation fails
  def policy_compliant_values_for_item(request)
    return [] unless constraints

    results = []
    unless constraints.empty?
      values = []
      route_gates = constraints.map(&:constrainable)
      unless route_gates.empty?
        route_gates.sort! { |a,b| a.position <=> b.position }
        route_gates.each do |route_gate|
          # see if it is for the same app
          if route_gate.route_app_id == request.app_ids.try(:first)
            values << route_gate.environment
          end
        end
        results = values if values.present?
      end
    end
    results
  end

  private

  def policy_compliant_values
    if constraints.present?
      constraints.map { |c| [c.constrainable.route_app_id, c.constrainable.environment_id] }.uniq
    else
      []
    end
  end

  def governable_supported?
    case governable.class.name
      when 'PlanStageInstance' then
        true
      else
        false
    end
  end

  def constrainable_supported?
    illegal_constrainable_types.blank?
  end

  def illegal_constrainable_types
    constraints.select { |c| c.constrainable_type != 'RouteGate' }.map(&:constrainable_type).uniq.sort
  end

  def strict_respected?
    # if the two do not match in strictness, they should never have been paired
    # and if they are both strict but are of different types, then again that is a mistake
    # but it is ok not to match if the environment types are both not strict
    constraint_strictness = constraints.map { |c| c.constrainable.try(:strict?) }
    case
      when constraint_strictness.include?(!governable.strict?)
        # the strictness of the governable entity and the constraints can never not match
        # so return false if any non-matching values for strict are found
        false
      when governable.strict? && illegal_constrainable_types.present?
        # double check that no strict type constraints are nonetheless pointed
        # at non-matching environment types, which is prohibited by validations but should
        # display an error if it happens somehow
        false
      else
        true
    end
  end

  def error_message_for_item(request = nil)
    msg = []
    if request
      msg << (request.environment_name ? "#{ request.environment_name} for" : 'Environment for')
      msg << (request.id ? "Request #{ request.number }" : 'new Request')
      msg << 'is not among routed environments for'
      msg << (request.app_name ? "#{ request.app_name.to_sentence }:" : 'the Application:')
      msg << "#{ policy_compliant_value_labels_for_item(request) }"
      msg.join(' ')
    else
      'Request is not among routed environments'
    end
  end

end
