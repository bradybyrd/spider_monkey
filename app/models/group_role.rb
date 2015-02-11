################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class GroupRole < ActiveRecord::Base
  belongs_to :group
  belongs_to :role

  acts_as_audited protect: false
end
