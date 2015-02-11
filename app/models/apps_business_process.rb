################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AppsBusinessProcess < ActiveRecord::Base
  belongs_to :app
  belongs_to :business_process
end
