################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class StepExecutionCondition < ActiveRecord::Base
  belongs_to :referenced_step, :class_name => 'Step'
  belongs_to :property
  belongs_to :runtime_phase
  belongs_to :step

  attr_accessible  :referenced_step_id, :value, :property_id, :runtime_phase_id,
                   :condition_type, :environment_ids, :environment_type_ids

  # an association that allows procedure (via step execution condition) to be governed by constraints such
  # as environment or environment type
  has_many :constraints, :as => :governable, :dependent => :destroy
  has_many :environments, through: :constraints, :source => :constrainable, :source_type => 'Environment'
  has_many :environment_types, through: :constraints, :source => :constrainable, :source_type => 'EnvironmentType'

  validates :step_id, :presence => true
  validates :referenced_step_id, :presence => true #, :if => Proc.new { |condition| condition.condition_type == 'property' or condition.condition_type == 'runtime_phase' }
  validates :value, :property_id, :presence => true, :if => Proc.new { |condition| condition.condition_type == 'property' }
  validates :runtime_phase_id, :presence => true, :if => Proc.new { |condition| condition.condition_type == 'runtime_phase' }

  scope :get_by_referenced_step, lambda { |referenced_step_ids|
    where('step_execution_conditions.referenced_step_id IN (?)', referenced_step_ids)
  }

  def met?
    case condition_type
      when 'property'
        cur_val = referenced_step.literal_property_value_for(property, referenced_step.try(:installed_component))
        # cur_val = property.literal_display_value_for(referenced_step.installed_component)
        cur_val == value
      when 'runtime_phase'
        runtime_phase_id == referenced_step.try(:runtime_phase_id)
      when 'environments'
        validate.blank?
      when 'environment_types'
        validate.blank?
      else
        raise 'Unknown condition type'
    end
  end

  def condition_check_messages
    if condition_type == 'environments' or condition_type == 'environment_types'
      validate
    else
      validate_old
    end
  end

  def validate_old
    result = []
    case condition_type
      when 'property'
        unless value == referenced_step.literal_property_value_for(property, referenced_step.try(:installed_component))
          msg = []
          msg << "Step '#{referenced_step.name}'"
          msg << 'is not among constrained property:'
          msg << "\nExpected that step's property '#{property.name}' to have value '#{value}'"
          #msg << " but it have #{real_value}"

          result << ConstraintValidationOutcome.new(self, nil, false, msg.join(' '))
        end
      when 'runtime_phase'
        unless runtime_phase_id == referenced_step.try(:runtime_phase_id)
          msg = []
          msg << "Step '#{referenced_step.name}'"
          msg << 'is not among constrained property:'
          msg << "\nExpected that step's runtime phase is '#{RuntimePhase.find(runtime_phase_id).name}'"
          #msg << " but it have #{real_value}"

          result << ConstraintValidationOutcome.new(self, nil, false, msg.join(' '))
        end
      else
        raise 'Unknown condition type'
    end
    result
  end


  # a grouped array of constraint totals by type
  def constraints_by_type
    constraints.order('constrainable_type ASC').group_by(&:constrainable_type)
  end

  # a standard constrain validation routine to check if a governable object
  # is valid according to its constraints and takes actions
  # returns a validation object with messages
  def validate
    policy_outcomes = []
    #run through the constraints by type and apply the right policy
    # and accumulate message objects
    constraints_by_type.each do |type, constraints|
      case type
        when 'Environment'
          policy_outcomes << EnvironmentPolicy.new(self, constraints).validate
        when 'EnvironmentType'
          policy_outcomes << EnvironmentTypePolicy.new(self, constraints).validate
        else
          logger.error("Constraint Validation Error: Unsupported constrainable_type #{type}.")
          policy_outcomes << ConstraintValidationOutcome.new(self, nil, false,
                                                         "Constrainable model of type #{type} is not supported.")
      end
    end

    # get rid of spurious empty arrays
    policy_outcomes.flatten!

    policy_outcomes
  end

  def constraint_post_delete
    self.destroy if (condition_type=='environments' or condition_type=='environment_types') and constraints.size==0
  end

end
