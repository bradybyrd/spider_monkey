################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AssignedApp < ActiveRecord::Base
  attr_accessible :user_id, :app_id, :team_id

  belongs_to :user # TODO: this should be changed to :group
  belongs_to :app
  belongs_to :team

  validates :user_id,
            :presence => true,
            :uniqueness => {:scope => [:app_id, :team_id]}
  validates :app_id,
            :presence => true

  scope :by_user_and_apps, ->(user, apps) { where(user_id: user, app_id: apps) }

  class << self

    def delete_with_callback(conditions)
      connection.execute("DELETE FROM assigned_apps WHERE #{conditions}")
    end

  end

end
