################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class UserGroup < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  acts_as_audited protect: false

  scope :root, lambda { where(group_id: Group.root_group_ids) }

  def self.root_user_ids
    root.pluck(:user_id)
  end
end
