################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ChangeDefaultOfActiveColumnOfPackageTemplates < ActiveRecord::Migration
  def self.up
      change_column_default(:package_templates, :active, true)
  end

  def self.down
    change_column_default(:package_templates, :active, nil)
  end
end
