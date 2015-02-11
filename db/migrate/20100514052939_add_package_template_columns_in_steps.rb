################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddPackageTemplateColumnsInSteps < ActiveRecord::Migration
  def self.up
    add_column :steps, :package_template_id, :integer
    add_column :steps, :package_template_properties, :text
  end

  def self.down
    remove_column :steps, :package_template_id
    remove_column :package_template_properties
  end
end
