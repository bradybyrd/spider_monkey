################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateServiceNowDatas < ActiveRecord::Migration
  def self.up
    create_table :service_now_data do |t|
      t.integer :project_server_id
      t.string :name
      t.string :sys_id
      t.string :table_name
      t.timestamps
    end
  end

  def self.down
    drop_table :service_now_data
  end
end
