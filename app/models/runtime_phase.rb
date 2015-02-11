################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class RuntimePhase < ActiveRecord::Base

  normalize_attributes :name

  belongs_to :phase
  has_many :step_execution_conditions

  validates :name,
            :presence => true,
            :uniqueness => {:scope => :phase_id}
          
  validates  :phase,:presence => true
  
  scope :in_order, order('runtime_phases.position')

  acts_as_list :scope => :phase

  attr_accessible :name, :phase, :insertion_point

  before_destroy :destroyable?

  def destroyable?
    if Step.find_by_runtime_phase_id(id) || StepExecutionCondition.find_by_runtime_phase_id(id)
      false
    else
      true
    end
  end

  def insertion_point
    position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end
end

