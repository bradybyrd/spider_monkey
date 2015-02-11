################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

class EnvironmentPolicy

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
                   ConstraintValidationOutcome.new(governable, nil, false, "Environment policy cannot be applied to objects of type #{ governable.class.name }")
                 when !constrainable_supported?
                   ConstraintValidationOutcome.new(governable, nil, false, "Environment policy cannot enforce constraints of type #{ illegal_constrainable_types.to_sentence }")
                 else
                   # if nothing seems insane about the governable and constraint situation
                   # now check if the request's environment match any of environments from step execution condition's constraints
                   validate_contents
               end
    results.flatten
  end

  def validate_contents
    results = []
    step = Step.find(governable.step_id)
    results << validate_item(step)
    results.compact
  end

  def validate_item(step)
    test_value = step.request.environment.id
    if policy_compliant_values.include?(test_value)
      nil
    else
      ConstraintValidationOutcome.new(governable, step, false, error_message_for_item(step))
    end
  end

  # a helper to provide legal alternatives when validation fails
  def policy_compliant_value_labels_for_item
    labels = policy_compliant_values_for_item.map(&:name)
    if labels.present?
      labels.to_sentence
    else
      'None'
    end
  end

  # a helper to provide legal alternatives when validation fails
  def policy_compliant_values_for_item
    return [] unless constraints

    results = []
    unless constraints.empty?
      values = []
      environments = constraints.map(&:constrainable)
      unless environments.empty?
        environments.each do |environment|
          values << environment
        end
        results = values if values.present?
      end
    end
    results
  end

  private

  def policy_compliant_values
    if constraints.present?
      constraints.map(&:constrainable_id).uniq
    else
      []
    end
  end

  def governable_supported?
    case governable.class.name
      when 'StepExecutionCondition' then
        true
      else
        false
    end
  end

  def constrainable_supported?
    illegal_constrainable_types.blank?
  end

  def illegal_constrainable_types
    constraints.select { |c| c.constrainable_type != 'Environment' }.map(&:constrainable_type).uniq.sort
  end

  def error_message_for_item(step = nil)
    msg = []
    request = step.request
    if step
      msg << "Environment '#{request.environment_name}'"
      msg << "from Request #{request.number}"
      msg << "'#{request.name}'"
      msg << 'is not among constrained environment(s):'
      msg << "\n#{ policy_compliant_value_labels_for_item }"
      msg.join(' ')
    else
      'Step is not among constrained environment(s)'
    end
  end

end
