################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddIndexesToAllColumns < ActiveRecord::Migration
  def self.up
    add_index :activities, :user_id
    add_index :activities, :activity_category_id
    add_index :activities, :current_phase_id
    add_index :activities, :manager_id
    add_index :activities, :leading_group_id
    
    add_index :activity_attribute_values, :activity_id
    add_index :activity_attribute_values, :activity_attribute_id
    add_index :activity_attribute_values, :value_object_id
    
    add_index :activity_creation_attributes, :activity_category_id
    add_index :activity_creation_attributes, :activity_attribute_id
    
    add_index :activity_deliverables, :activity_id
    add_index :activity_deliverables, :activity_phase_id
    add_index :activity_deliverables, :deployment_contact_id
    
    add_index :activity_index_columns, :activity_category_id
    
    # add_index :activity_logs, :request_id #Index is already created in earlier migrations
    add_index :activity_logs, :user_id
    
        
    add_index :budget_line_items , :group_id
    # add_index :budget_line_items, :activity_id #Index is already created in earlier migrations
    add_index :budget_line_items, :user_id
    
  
    add_index :email_recipients, :recipient_id
        
    add_index :list_items, :list_id
    
    add_index :messages, :sender_id
    
    add_index :notes, :user_id
    # add_index :notes, :step_id #Index is already created in earlier migrations

    
    add_index :parent_activities, :container_id
    add_index :parent_activities, :activity_id
    
    add_index :preferences, :user_id
    
    add_index :recent_activities, :actor_id
    add_index :recent_activities, :object_id
    add_index :recent_activities, :indirect_object_id
    
    
    add_index :resource_allocations, :allocated_id
        
    add_index :security_answers, :user_id
        
                    
    add_index :teams_groups, :group_id                
    add_index :teams_groups, :team_id    
    
    add_index :teams_roles, :team_id    
    add_index :teams_roles, :user_id    
    
    add_index :teams_users, :team_id    
    add_index :teams_users, :user_id    
    
    add_index :workstreams, :resource_id
    add_index :workstreams, :activity_id
    
    add_index :temporary_budget_line_items, :group_id, :name => 'tbli_group_id'
    add_index :temporary_budget_line_items, :activity_id, :name => 'tbli_activity_id'
    add_index :temporary_budget_line_items, :budget_line_item_id, :name => 'tbli_budget_line_item_id'
    add_index :temporary_budget_line_items, :user_id, :name => 'tbli_user_id'
            
  end

  def self.down
    remove_index :activities, :user_id
    remove_index :activities, :activity_category_id
    remove_index :activities, :current_phase_id
    remove_index :activities, :manager_id
    remove_index :activities, :leading_group_id

    remove_index :activity_attribute_values, :activity_id
    remove_index :activity_attribute_values, :activity_attribute_id
    remove_index :activity_attribute_values, :value_object_id

    remove_index :activity_creation_attributes, :activity_category_id
    remove_index :activity_creation_attributes, :activity_attribute_id

    remove_index :activity_deliverables, :activity_id
    remove_index :activity_deliverables, :activity_phase_id
    remove_index :activity_deliverables, :deployment_contact_id

    remove_index :activity_index_columns, :activity_category_id

    remove_index :activity_logs, :user_id

    remove_index :budget_line_items , :group_id

    
    # remove_index :budget_line_items, :activity_id #Index is already created in earlier migrations
    
    remove_index :budget_line_items, :user_id

    remove_index :containers, :group_id
    remove_index :containers, :manager_id

    remove_index :development_teams, :team_id

    remove_index :email_recipients, :recipient_id

    remove_index :list_items, :list_id

    remove_index :messages, :sender_id
    remove_index :messages, :request_id

    remove_index :notes, :user_id

    remove_index :parent_activities, :container_id
    remove_index :parent_activities, :activity_id

    remove_index :preferences, :user_id

    remove_index :recent_activities, :actor_id
    remove_index :recent_activities, :object_id
    remove_index :recent_activities, :indirect_object_id

    remove_index :resource_allocations, :allocated_id

    remove_index :security_answers, :user_id

    remove_index :teams_groups, :group_id                
    remove_index :teams_groups, :team_id    

    remove_index :teams_roles, :team_id    
    remove_index :teams_roles, :user_id    

    remove_index :teams_users, :team_id    
    remove_index :teams_users, :user_id    

    remove_index :user_groups, :user_id
    remove_index :user_groups, :group_id   

    remove_index :workstreams, :resource_id
    remove_index :workstreams, :activity_id
    

    remove_index :temporary_budget_line_items, :name => 'tbli_group_id'
    remove_index :temporary_budget_line_items, :name => 'tbli_activity_id'
    remove_index :temporary_budget_line_items, :name => 'tbli_budget_line_item_id'
    remove_index :temporary_budget_line_items, :name => 'tbli_user_id'
                
  end
end
