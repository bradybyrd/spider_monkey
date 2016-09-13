################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddIndexesToColumnsOfRemainingTables < ActiveRecord::Migration
  def self.up
    add_index :activities_lifecycle_members, :activity_id
    
    add_index :activity_attributes, :list_id
    
    add_index :activity_notes, :activity_id
    add_index :activity_notes, :user_id
        
    add_index :activity_tab_attributes, :activity_tab_id
    add_index :activity_tab_attributes, :activity_attribute_id
    
    add_index :activity_phases, :activity_category_id
    
    add_index :activity_tabs, :activity_category_id
        
    add_index :calendar_reports, :user_id
        
    add_index :default_tabs, :user_id
    
    add_index :group_management, :manager_id
    add_index :group_management, :group_id    
        
    add_index :lists, :created_by_id
                     
    add_index :teams, :user_id 
    
  end

  def self.down
    remove_index :activities_lifecycle_members, :activity_id

    remove_index :activity_attributes, :list_id

    remove_index :activity_notes, :activity_id
    remove_index :activity_notes, :user_id
    
    remove_index :activity_tab_attributes, :activity_tab_id
    remove_index :activity_tab_attributes, :activity_attribute_id

    remove_index :activity_phases, :activity_category_id

    remove_index :activity_tabs, :activity_category_id

    remove_index :calendar_reports, :user_id

    remove_index :default_tabs, :user_id
        
    remove_index :group_management, :manager_id
    remove_index :group_management, :group_id 
        
    remove_index :lists, :created_by_id
            
    remove_index :teams, :user_id 
    
    
  end
end
