################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class TeamGroup < ActiveRecord::Base
  belongs_to  :group
  belongs_to  :team
  has_one     :team_group_app_env_role

  acts_as_audited protect: false
end
