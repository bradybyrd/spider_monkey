################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CreateQueryDetails < ActiveRecord::Migration
  def self.up
    create_table :query_details do |t|
      t.integer :query_id
      t.string  :query_element
      t.string  :query_criteria
      t.string  :query_term
      t.string  :conjuction
      t.timestamps
    end
  end

  def self.down
    drop_table :query_details
  end
end
