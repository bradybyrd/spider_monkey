################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PlanTeam < ActiveRecord::Base
    
  attr_accessible :plan_id, :team_id, :plan, :team
  
  validates :plan_id,:presence => true
  validates :team_id,:presence => true
  
  belongs_to :plan
  belongs_to :team
  
end
