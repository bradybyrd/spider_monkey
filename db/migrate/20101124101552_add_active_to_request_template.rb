################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddActiveToRequestTemplate < ActiveRecord::Migration
  def self.up
    add_column :request_templates, :active, :boolean, :default => true
  end

  def self.down
    remove_column :request_templates, :active
  end
end
