################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreatePackageTemplates < ActiveRecord::Migration
  def self.up
    create_table :package_templates do |t|
      t.string  :name
      t.string  :version
      t.integer :app_id
      t.boolean :active
      t.timestamps
    end
  end

  def self.down
    drop_table :package_templates
  end
end
