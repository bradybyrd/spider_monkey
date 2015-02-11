################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class UserApp < ActiveRecord::Base

  # Sri - This model is not used anymore

  validates :user_id, presence: true
  validates :app_id, presence: true

  serialize :roles, Hash

  belongs_to :user
  belongs_to :app

  scope :of_user, lambda {|user_id| {conditions: {user_id: user_id}}}
  scope :visible, where(visible: true)

  before_save :set_roles

  def accessible_env_ids # Duplicate in TeamRole
    env_role_mapping.keys
  end

  def env_role_mapping
    roles.delete_if {|_, v| v.blank? }
  end

  private

  def set_roles
    write_attribute(:roles, roles.except('visible'))
  end

end
