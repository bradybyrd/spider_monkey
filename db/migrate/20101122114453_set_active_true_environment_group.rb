################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class SetActiveTrueEnvironmentGroup < ActiveRecord::Migration    
  def self.up
    change_table :environment_groups do |t|
      t.change :active, :boolean,  :default => true
    end
  end

  def self.down
    change_table :environment_groups do |t|
      t.change :active, :boolean,  :default => false
    end
  end
end
