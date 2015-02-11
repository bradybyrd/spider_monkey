################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AlterQueriesAndReleaseContents < ActiveRecord::Migration
  def self.up
    add_column :queries, :name, :string
    add_column :queries, :project, :string
    add_column :queries, :iteration, :string
    add_column :queries, :release, :string
    
    add_column :queries, :rally_project_id, :integer
    add_column :queries, :rally_iteration_id, :integer
    add_column :queries, :rally_release_id, :integer
    add_column :queries, :last_run_at, :datetime
    add_column :queries, :last_run_by, :integer
    
    # Alter Release Contents
    add_column :release_contents, :iteration, :string
    add_column :release_contents, :release, :string
    change_column :release_contents, :description, :text unless OracleAdapter
    change_column :release_contents, :description, "long" if OracleAdapter 
  end

  def self.down
    remove_column :queries, :name
    remove_column :queries, :project
    remove_column :queries, :iteration
    remove_column :queries, :release
    
    remove_column :queries, :rally_project_id
    remove_column :queries, :rally_iteration_id
    remove_column :queries, :rally_release_id
    remove_column :queries, :last_run_at
    remove_column :queries, :last_run_by

    # Alter Release Contents
    remove_column :release_contents, :iteration
    remove_column :release_contents, :release
    change_column :release_contents, :description, :string unless OracleAdapter
    change_column :release_contents, :description, :string if OracleAdapter
  end
end
