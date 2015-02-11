################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityNote < ActiveRecord::Base
  belongs_to :user
  belongs_to :activity

  validates :user_id,
            :presence => true
  validates :activity_id,
            :presence => true
  validates :contents,
            :presence => true
  attr_accessible :user_id, :activity_id, :contents

  delegate :name, :to => :user, :prefix => true
end