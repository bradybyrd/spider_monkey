################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class AssignedEnvironment < ActiveRecord::Base

  attr_accessible :assigned_app_id, :environment_id, :role
  
  belongs_to :environment
  belongs_to :assigned_app
  has_one :app, through: :assigned_app
  has_one :user, through: :assigned_app

  validates :assigned_app_id, :presence => true
  validates :environment_id, :presence => true
  validates :role, :presence => true

  delegate :name, to: :app, prefix: true, allow_nil: true
  delegate :id,   to: :app, prefix: true, allow_nil: true
  delegate :name, to: :environment, prefix: true, allow_nil: true
  
  class << self
    def delete_with_callback(conditions)
      connection.execute("DELETE FROM assigned_environments WHERE #{conditions}")
    end

    def delete_all_having_no_parent
      connection.execute("DELETE FROM assigned_environments WHERE assigned_environments.assigned_app_id NOT IN (SELECT assigned_apps.id FROM assigned_apps)")
    end

  end

end
