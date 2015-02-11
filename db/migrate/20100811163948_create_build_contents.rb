################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateBuildContents < ActiveRecord::Migration
  def self.up
    create_table :build_contents do |t|
      t.integer   :query_id
      t.integer   :lifecycle_id
      t.string    :object_i_d
      t.string    :message
      t.string    :status
      t.string    :project
      t.timestamps
    end
  end

  def self.down
    drop_table :build_contents
  end
end
