################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ChangeColumnActivityIdOfActivityAttributeValues < ActiveRecord::Migration
  
  # TODO - Verify in Oracle
  
  def self.up
    change_column :activity_attribute_values, :activity_id, :integer, :null => true
  end

  def self.down
    change_column :activity_attribute_values, :activity_id, :integer, :null => false
  end
end
