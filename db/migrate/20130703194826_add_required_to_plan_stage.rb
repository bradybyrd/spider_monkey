################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddRequiredToPlanStage < ActiveRecord::Migration
  def change
    add_column :plan_stages, :required, :boolean, :default => false, :null => false
    add_index :plan_stages, :required, :name => 'I_PS_REQUIRED'
  end
end
