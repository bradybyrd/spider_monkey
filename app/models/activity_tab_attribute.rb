################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityTabAttribute < ActiveRecord::Base
  belongs_to :activity_tab
  belongs_to :activity_attribute

  attr_accessible :disabled
  acts_as_list :scope => :activity_tab_id
end
