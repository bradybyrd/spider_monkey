################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreatePackageTemplateComponents < ActiveRecord::Migration
  def self.up
    create_table :package_template_components do |t|
      t.integer :package_template_item_id
      t.integer :application_component_id
      t.timestamps
    end
  end

  def self.down
    drop_table :package_template_components
  end
end
