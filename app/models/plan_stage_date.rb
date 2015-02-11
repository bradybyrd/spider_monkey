################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PlanStageDate < ActiveRecord::Base
  
  attr_accessible :plan_id, :plan_stage_id, :start_date, :end_date, :plan_stage, :plan
  
  belongs_to :plan_stage
  belongs_to :plan
  
  validates :plan_stage_id, :plan_id, :presence => true
  validates :plan_stage_id, :uniqueness => { :scope => :plan_id }
  
end
