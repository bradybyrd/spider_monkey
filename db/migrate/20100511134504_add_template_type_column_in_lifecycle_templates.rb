################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddTemplateTypeColumnInLifecycleTemplates < ActiveRecord::Migration
  def self.up
    add_column :lifecycle_templates, :template_type, :string
  end

  def self.down
    remove_column :lifecycle_templates, :template_type
  end
end
