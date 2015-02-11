################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class EnvironmentServerGroup < ActiveRecord::Base
  self.table_name = :environments_server_groups
  belongs_to :environment
  belongs_to :server_group

  attr_accessible :server_group_id, :environment_id

end
