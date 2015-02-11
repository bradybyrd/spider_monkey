################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateIntegrationCsvDatas < ActiveRecord::Migration
  def self.up
    create_table :integration_csv_data do |t|
      t.integer :integration_csv_column_id
      t.text    :value
      t.timestamps
    end
  end

  def self.down
    drop_table :integration_csv_data
  end
end
