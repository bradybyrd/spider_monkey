################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PropertyWorkTask < ActiveRecord::Base
  belongs_to :property
  belongs_to :work_task

  validates :property,:presence => true
  validates :work_task, :presence => true

  attr_accessible :work_task_id, :entry_during_step_execution

  scope :on_execution, where(:entry_during_step_execution => true)
  scope :on_creation, where(:entry_during_step_creation => true)
end
