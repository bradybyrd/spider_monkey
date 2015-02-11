################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateReleaseContents < ActiveRecord::Migration
  def self.up
    create_table :release_contents do |t|
      t.integer   :query_id
      t.integer   :lifecycle_id
      t.string    :formatted_i_d
      t.string    :name
      t.string    :schedule_state
      t.string    :owner
      t.string    :project
      t.string    :package
      t.string    :description
      t.datetime  :creation_date
      t.datetime  :last_update_date
      t.datetime  :accepted_date
      t.timestamps
    end
  end

  def self.down
    drop_table :release_contents
  end
end
