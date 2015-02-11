################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnAppIdToSteps < ActiveRecord::Migration
  def self.up
    add_column  :steps, :app_id, :integer    
  end

  def self.down
    remove_column :steps, :app_id    
  end
end
