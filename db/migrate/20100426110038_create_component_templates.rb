################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateComponentTemplates < ActiveRecord::Migration
  def self.up
    create_table :component_templates do |t|
      t.string :name
      t.string :version
      t.integer :application_component_id
      t.integer :app_id
      t.boolean :active, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :component_templates
  end
end
