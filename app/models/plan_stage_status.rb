################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PlanStageStatus < ActiveRecord::Base
  
  attr_accessible :name, :plan_stage_id, :plan_stage, :position
  
  belongs_to :stage, :class_name => "PlanStage", :foreign_key => :plan_stage_id

  validates :name,
            :presence => true,
            :uniqueness => {:scope => :plan_stage_id, :case_sensitive => false}
  validates :plan_stage_id,
            :presence => true
  

  acts_as_list :scope => :plan_stage_id
end
