################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ServerLevelProperty < ActiveRecord::Base
  belongs_to :server_level
  belongs_to :property

  validates :server_level,
            :presence => true
  validates :property,
            :presence => true
end
