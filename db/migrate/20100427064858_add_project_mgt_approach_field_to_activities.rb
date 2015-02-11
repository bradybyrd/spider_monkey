################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddProjectMgtApproachFieldToActivities < ActiveRecord::Migration
  def self.up
    add_column :activities, :project_mgt_approach, :string 
  end

  def self.down
    remove_column :activities, :project_mgt_approach
  end
end
