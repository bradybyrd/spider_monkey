################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddIndexesToColumnsOfRemainingTables < ActiveRecord::Migration
  def self.up
    add_index :activities_lifecycle_members, :activity_id
    add_index :activities_lifecycle_members, :lifecycle_member_id
    
    add_index :activity_attributes, :list_id
    
    add_index :activity_notes, :activity_id
    add_index :activity_notes, :user_id
        
    add_index :activity_tab_attributes, :activity_tab_id
    add_index :activity_tab_attributes, :activity_attribute_id
    
    add_index :activity_phases, :activity_category_id
    
    add_index :activity_tabs, :activity_category_id
    
    add_index :assigned_environments, :environment_group_id
    
    add_index :bladelogic_scripts, :tag_id
    add_index :bladelogic_scripts, :integration_id
    add_index :bladelogic_scripts, :template_script_id
    
    add_index :calendar_reports, :user_id
    
    add_index :capistrano_scripts, :tag_id
    add_index :capistrano_scripts, :integration_id
    add_index :capistrano_scripts, :template_script_id

    add_index :component_templates, :application_component_id
    add_index :component_templates, :app_id
    
    add_index :default_tabs, :user_id

    add_index :environments_server_groups, :environment_id
    add_index :environments_server_groups, :server_group_id  
    
    add_index :export_import_sessions, :user_id 
    
    add_index :export_logs, :user_id
    
    add_index :group_management, :manager_id
    add_index :group_management, :group_id    
    
    add_index :icsags, :installed_component_id
    add_index :icsags, :server_aspect_group_id
    
    add_index :icsas, :installed_component_id
    add_index :icsas, :server_aspect_id
    
    add_index :installed_components_servers, :installed_component_id
    add_index :installed_components_servers, :server_id
    
    add_index :lists, :created_by_id
                 
    add_index :properties_servers, :property_id
    add_index :properties_servers, :server_id
    
    add_index :sagsas, :server_aspect_group_id
    add_index :sagsas, :server_aspect_id
    
    add_index :satpms, :script_argument_id
    add_index :satpms, :property_id
    add_index :satpms, :value_holder_id
    
    add_index :scripts, :integration_id
    add_index :scripts, :template_script_id
    add_index :scripts, :tag_id
    
    add_index :server_aspects_steps, :server_aspect_id
    add_index :server_aspects_steps, :step_id
    
    add_index :server_groups_servers, :server_group_id
    add_index :server_groups_servers, :server_id
    
    add_index :server_groups_steps, :server_group_id
    add_index :server_groups_steps, :step_id
    
    add_index :teams, :user_id 
    
  end

  def self.down
    remove_index :activities_lifecycle_members, :activity_id
    remove_index :activities_lifecycle_members, :lifecycle_member_id

    remove_index :activity_attributes, :list_id

    remove_index :activity_notes, :activity_id
    remove_index :activity_notes, :user_id
    
    remove_index :activity_tab_attributes, :activity_tab_id
    remove_index :activity_tab_attributes, :activity_attribute_id

    remove_index :activity_phases, :activity_category_id

    remove_index :activity_tabs, :activity_category_id

    remove_index :assigned_environments, :environment_group_id
    
    remove_index :bladelogic_scripts, :tag_id
    remove_index :bladelogic_scripts, :integration_id
    remove_index :bladelogic_scripts, :template_script_id

    remove_index :calendar_reports, :user_id

    remove_index :capistrano_scripts, :tag_id
    remove_index :capistrano_scripts, :integration_id
    remove_index :capistrano_scripts, :template_script_id

    remove_index :component_templates, :application_component_id
    remove_index :component_templates, :app_id
    
    remove_index :default_tabs, :user_id

    remove_index :environments_server_groups, :environment_id
    remove_index :environments_server_groups, :server_group_id
    
    remove_index :export_import_sessions, :user_id
    
    remove_index :export_logs, :user_id
    
    remove_index :group_management, :manager_id
    remove_index :group_management, :group_id 
    
    remove_index :icsags, :installed_component_id
    remove_index :icsags, :server_aspect_group_id
    
    remove_index :icsas, :installed_component_id
    remove_index :icsas, :server_aspect_id
    
    remove_index :installed_components_servers, :installed_component_id
    remove_index :installed_components_servers, :server_id
    
    remove_index :lists, :created_by_id
        
    remove_index :properties_servers, :property_id
    remove_index :properties_servers, :server_id
    
    remove_index :sagsas, :server_aspect_group_id
    remove_index :sagsas, :server_aspect_id
    
    remove_index :satpms, :script_argument_id
    remove_index :satpms, :property_id
    remove_index :satpms, :value_holder_id
    
    remove_index :scripts, :integration_id
    remove_index :scripts, :template_script_id
    remove_index :scripts, :tag_id
    
    remove_index :server_aspects_steps, :server_aspect_id
    remove_index :server_aspects_steps, :step_id
    
    remove_index :server_groups_servers, :server_group_id
    remove_index :server_groups_servers, :server_id
    
    remove_index :server_groups_steps, :server_group_id
    remove_index :server_groups_steps, :step_id   
    
    remove_index :teams, :user_id 
    
    
  end
end
