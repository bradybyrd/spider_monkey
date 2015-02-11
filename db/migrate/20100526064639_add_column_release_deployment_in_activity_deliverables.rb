################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnReleaseDeploymentInActivityDeliverables < ActiveRecord::Migration
  def self.up
    add_column :activity_deliverables, :release_deployment, :boolean, :default => false
  end

  def self.down
    remove_column :activity_deliverables, :release_deployment
  end
end
