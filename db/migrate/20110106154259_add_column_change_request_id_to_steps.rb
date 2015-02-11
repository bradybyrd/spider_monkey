################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnChangeRequestIdToSteps < ActiveRecord::Migration
  def self.up
    add_column :steps, :change_request_id, :integer
  end

  def self.down
    remove_column :steps, :change_request_id
  end
end
