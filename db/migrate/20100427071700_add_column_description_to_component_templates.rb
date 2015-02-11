################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddColumnDescriptionToComponentTemplates < ActiveRecord::Migration
  def self.up
    add_column :component_templates, :description, :text
  end

  def self.down
    remove_column :component_templates, :description
  end
end
