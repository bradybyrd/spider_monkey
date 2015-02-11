################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddArtifactsToQueries < ActiveRecord::Migration
  def self.up
    add_column :queries, :artifacts, :string
    change_column :queries, :rally_project_id, :string
  end

  def self.down
    remove_column :queries, :artifacts
    change_column :queries, :rally_project_id, :integer
  end
end
