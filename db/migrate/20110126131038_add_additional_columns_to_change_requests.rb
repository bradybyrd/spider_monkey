################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddAdditionalColumnsToChangeRequests < ActiveRecord::Migration
  def self.up
    add_column :change_requests, :u_application_name, :string
    add_column :change_requests, :u_stage, :string
    add_column :change_requests, :cr_state, :string
    add_column :change_requests, :u_version_tag, :string
  end

  def self.down
    remove_column :change_requests, :u_application_name
    remove_column :change_requests, :u_stage
    remove_column :change_requests, :state
    remove_column :change_requests, :u_version_tag
  end
end
