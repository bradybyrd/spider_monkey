################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# Since this table will be removed and `scripts` will be used instead these columns will 
# also be removed. They for time being until `bladelogic_scripts` & `capistrano_scripts` exist

class AddColumnTagToBladelogicAndCapistranoScripts < ActiveRecord::Migration
  def self.up
    add_column :bladelogic_scripts, :tag_id, :integer 
    add_column :capistrano_scripts, :tag_id, :integer
  end

  def self.down
    remove_column :bladelogic_scripts, :tag_id
    remove_column :capistrano_scripts, :tag_id
  end
end
