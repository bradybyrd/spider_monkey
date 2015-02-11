################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddTokenToSteps < ActiveRecord::Migration
  def self.up
    add_column :steps, :token, :string
  end

  def self.down
    remove_column :steps, :token
  end
end
