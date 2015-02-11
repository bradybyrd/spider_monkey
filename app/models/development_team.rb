################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class DevelopmentTeam < ActiveRecord::Base

  belongs_to :team
  belongs_to :app

  acts_as_audited protect: false

end
