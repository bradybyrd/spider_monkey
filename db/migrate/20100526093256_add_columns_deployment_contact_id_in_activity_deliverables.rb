################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnsDeploymentContactIdInActivityDeliverables < ActiveRecord::Migration
  def self.up
    add_column :activity_deliverables, :deployment_contact_id, :integer
  end

  def self.down
    remove_column :activity_deliverables, :deployment_contact_id
  end
end
