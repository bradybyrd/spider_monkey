################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddRallyColumnsToIntegrationProjects < ActiveRecord::Migration
  def self.up
    add_column :integration_projects, :parent_id, :integer
    add_column :integration_projects, :object_i_d, :string
  end

  def self.down
    remove_column :integration_projects, :parent_id
    remove_column :integration_projects, :object_i_d
  end
end
