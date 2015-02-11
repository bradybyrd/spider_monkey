################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreatePackageTemplateItems < ActiveRecord::Migration
  def self.up
    create_table :package_template_items do |t|
      t.integer :package_template_id
      t.integer :position
      t.integer :item_type # Command => 1, # Component => 2
      t.string  :name
      t.string  :description
      t.integer :component_template_id
      t.text    :properties
      t.text    :commands
      t.timestamps
    end
  end

  def self.down
    drop_table :package_template_items
  end
end
