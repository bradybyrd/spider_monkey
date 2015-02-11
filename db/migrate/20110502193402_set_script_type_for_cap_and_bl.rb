################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class SetScriptTypeForCapAndBl < ActiveRecord::Migration
  def self.up
    execute "update capistrano_scripts set script_type = 'CapistranoScript'"
    execute "update bladelogic_scripts set script_type = 'BladelogicScript'"
  end

  def self.down
  end
end
