################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class BladelogicRole < ActiveRecord::Base
  belongs_to :user, :class_name => 'BladelogicUser', :foreign_key => 'bladelogic_user_id'
  
  validates :bladelogic_user_id,
            :uniqueness => {:scope => :name}
end
