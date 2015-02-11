################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class EnvironmentRole < ActiveRecord::Base
  
  # Sri - This model is not used anymore
  
  belongs_to :environment
  belongs_to :user
  
  validates :user_id,
            :presence => true
  validates :environment_id,
            :presence => true
  validates :role,
            :presence => true

end
