################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateIntegrationCsvColumns < ActiveRecord::Migration
  def self.up
    create_table :integration_csv_columns do |t|
      t.integer :integration_csv_id
      t.string  :name
      t.boolean :primary, :default => false
      t.boolean :active,  :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :integration_csv_columns
  end
end
