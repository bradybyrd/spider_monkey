################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ChangeColumnTagIdOfScriptsToInt < ActiveRecord::Migration
  def self.up
    # FIXME, Manish, 28 Nov 11, If the DB contains numeric tag_ids, this code needs to have string tag_ids converted to integer otherwise migration will fail.
    # FIXME, Manish, 28 Nov 11, DB specific code to be refactored with generic migration script.
    if PostgreSQLAdapter
      rename_column :scripts, :tag_id, :tag_id_temp
      add_column :scripts, :tag_id_int, :integer
      #      say_with_time "Changing tag_id column to Integer" do
      #        BudgetLineItem.all.each do |bli|
      #          bli.update_attribute(:approved_spend_int, 1000) #bli.year.try(:to_i))
      #        end
      #      end
      remove_column :scripts, :tag_id_temp
      rename_column :scripts, :tag_id_int, :tag_id
    else
      change_column :scripts, :tag_id, :integer
    end
  end

  def self.down
    change_column :scripts, :tag_id, :string
  end
end
