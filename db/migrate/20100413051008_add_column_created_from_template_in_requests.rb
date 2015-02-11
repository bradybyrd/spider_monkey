################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnCreatedFromTemplateInRequests < ActiveRecord::Migration
  def self.up
    add_column :requests, :created_from_template, :boolean, :default => false
  end

  def self.down
    remove_column :requests, :created_from_template
  end
end
