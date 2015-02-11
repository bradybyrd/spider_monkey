################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddIndexesToAllColumns < ActiveRecord::Migration
  def self.up
    add_index :activities, :app_id
    add_index :activities, :release_id
    add_index :activities, :user_id
    add_index :activities, :lifecycle_stage_id
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
    
    
    add_index :application_components, :app_id
    add_index :application_components, :component_id
    
    add_index :application_environments , :app_id
    add_index :application_environments , :environment_id
    
    add_index :apps_business_processes, :app_id
    add_index :apps_business_processes, :business_process_id
    
    add_index :apps_procedures, :app_id
    add_index :apps_procedures, :procedure_id
    
    add_index :apps_properties, :app_id
    add_index :apps_properties, :property_id
    
    add_index :apps_requests, :app_id
    add_index :apps_requests, :request_id

    
    add_index :assets, :owner_id
    
    add_index :assigned_apps, :user_id
    add_index :assigned_apps, :app_id    
    
    add_index :assigned_environments, :environment_id
    add_index :assigned_environments, :assigned_app_id
    
    add_index :bladelogic_roles, :bladelogic_user_id  
    
    add_index :bladelogic_script_arguments, :script_id
    
    add_index :bladelogic_users, :streamdeploy_user_id
    
    add_index :budget_line_items , :group_id
    # add_index :budget_line_items, :activity_id #Index is already created in earlier migrations
    add_index :budget_line_items, :user_id
    
    add_index :build_contents, :lifecycle_id
    add_index :build_contents, :query_id
    
    add_index :capistrano_script_arguments, :script_id
    
    add_index :change_requests, :lifecycle_id
    add_index :change_requests, :project_server_id
    add_index :change_requests, :query_id

    
    add_index :component_properties, :component_id
    add_index :component_properties, :property_id
    
    add_index :containers, :group_id
    add_index :containers, :manager_id
    
    add_index :development_teams, :team_id
    add_index :development_teams, :app_id
    
    add_index :email_recipients, :request_id
    add_index :email_recipients, :recipient_id
    
    add_index :environment_roles, :environment_id
    add_index :environment_roles, :user_id
    
    add_index :environment_servers, :environment_id
    add_index :environment_servers, :server_id
    add_index :environment_servers, :server_aspect_id
    
    add_index :environments, :default_server_group_id
        
    add_index :installed_components, :application_component_id
    add_index :installed_components, :application_environment_id
    add_index :installed_components, :reference_id
    
    add_index :integration_csv_columns, :integration_csv_id
    
    add_index :integration_csv_data, :integration_csv_column_id
    
    add_index :integration_csvs, :lifecycle_id
    add_index :integration_csvs, :project_server_id
    add_index :integration_csvs, :user_id
    
    add_index :integration_projects, :project_server_id
    
    add_index :integration_releases, :integration_project_id
    
    add_index :job_runs, :step_id
    
    add_index :lifecycle_activities, :lifecycle_id
    add_index :lifecycle_activities, :activity_id
    
    add_index :lifecycle_apps, :lifecycle_id
    add_index :lifecycle_apps, :app_id
    
    add_index :lifecycle_environments, :lifecycle_id
    add_index :lifecycle_environments, :environment_id
    add_index :lifecycle_environments, :environment_group_id
    
    add_index :lifecycle_members, :app_id
    add_index :lifecycle_members, :server_id
    add_index :lifecycle_members, :server_aspect_id
    add_index :lifecycle_members, :lifecycle_template_id
    add_index :lifecycle_members, :lifecycle_id
    add_index :lifecycle_members, :lifecycle_stage_id
    
    add_index :lifecycle_stage_dates, :lifecycle_stage_id
    
    add_index :lifecycle_stages, :request_template_id
    add_index :lifecycle_stages, :lifecycle_template_id
    
    add_index :lifecycle_teams, :lifecycle_id
    
    add_index :lifecycle_wikis, :lifecycle_id  
    
    add_index :lifecycles, :lifecycle_template_id
    add_index :lifecycles, :release_manager_id
    add_index :lifecycles, :release_id
    
    add_index :list_items, :list_id
    
    add_index :messages, :sender_id
    add_index :messages, :request_id
    
    add_index :notes, :user_id
    # add_index :notes, :step_id #Index is already created in earlier migrations

    
    add_index :package_template_components, :package_template_item_id
    add_index :package_template_components, :application_component_id
    
     add_index :package_template_items, :component_template_id
    
    add_index :package_templates, :app_id
    
    add_index :parent_activities, :container_id
    add_index :parent_activities, :activity_id
    
    add_index :preferences, :user_id
    
    add_index :property_tasks, :property_id
    add_index :property_tasks, :task_id
    
    add_index :property_values, :property_id
    add_index :property_values, :value_holder_id
    
    add_index :queries, :lifecycle_id
    add_index :queries, :project_server_id
    add_index :queries, :last_run_by
    
    add_index :query_details, :query_id
    
    add_index :recent_activities, :actor_id
    add_index :recent_activities, :object_id
    add_index :recent_activities, :indirect_object_id
    
    add_index :release_content_items, :lifecycle_id
    add_index :release_content_items, :integration_project_id
    add_index :release_content_items, :integration_release_id
    
    
    add_index :release_contents, :lifecycle_id
    add_index :release_contents, :query_id
    
    add_index :request_package_contents, :request_id
    add_index :request_package_contents, :package_content_id
    
    add_index :requests, :environment_id
    add_index :requests, :environment_group_id
    add_index :requests, :business_process_id
    add_index :requests, :deployment_coordinator_id
    add_index :requests, :requestor_id
    add_index :requests, :owner_id
    add_index :requests, :release_id
    add_index :requests, :category_id
    add_index :requests, :request_template_id
    add_index :requests, :activity_id
    add_index :requests, :lifecycle_member_id
    add_index :requests, :server_association_id
    
    add_index :resource_allocations, :allocated_id
    
    add_index :runtime_phases, :phase_id
    
    add_index :script_arguments, :script_id
    
    add_index :security_answers, :user_id
    
    add_index :server_aspects, :parent_id
    
    add_index :server_level_properties, :server_level_id
    add_index :server_level_properties, :property_id            
    
    add_index :step_execution_conditions, :referenced_step_id
    add_index :step_execution_conditions, :property_id  
              
    add_index :step_script_arguments, :step_id
    add_index :step_script_arguments, :script_argument_id 
               
    # add_index :steps, :request_id #Index is already created in earlier migrations

    add_index :steps, :app_id            

    add_index :steps, :parent_id
    add_index :steps, :procedure_id            
    add_index :steps, :owner_id
    add_index :steps, :component_id            
    # add_index :steps, :script_id #Index is already created in earlier migrations
    add_index :steps, :task_id            
    add_index :steps, :category_id
    add_index :steps, :phase_id            
    add_index :steps, :runtime_phase_id            
    add_index :steps, :package_template_id                  
    add_index :steps, :change_request_id
    
                    
    add_index :teams_groups, :group_id                
    add_index :teams_groups, :team_id    
    
    add_index :teams_roles, :team_id    
    add_index :teams_roles, :app_id    
    add_index :teams_roles, :user_id    
    
    add_index :teams_users, :team_id    
    add_index :teams_users, :user_id    
    
    add_index :temporary_property_values, :step_id        
    add_index :temporary_property_values, :property_id        
    add_index :temporary_property_values, :original_value_holder_id
            
    add_index :user_apps, :user_id            
    add_index :user_apps, :app_id 
    
    add_index :user_groups, :user_id
    add_index :user_groups, :group_id   
    
    add_index :workstreams, :resource_id
    add_index :workstreams, :activity_id
    
    add_index :temporary_budget_line_items, :group_id, :name => 'tbli_group_id'
    add_index :temporary_budget_line_items, :activity_id, :name => 'tbli_activity_id'
    add_index :temporary_budget_line_items, :budget_line_item_id, :name => 'tbli_budget_line_item_id'
    add_index :temporary_budget_line_items, :user_id, :name => 'tbli_user_id'
            
    add_index :server_aspects, :server_level_id, :name => 'sa_server_level_id'
            
    add_index :server_aspect_groups, :server_level_id, :name => 'sag_server_level_id' 
        
    add_index :servers_steps, :server_id
    add_index :servers_steps, :step_id
             
    add_index :request_templates, :team_id
    add_index :request_templates, :parent_id
            
  end

  def self.down
    remove_index :activities, :app_id
    remove_index :activities, :release_id
    remove_index :activities, :user_id
    remove_index :activities, :lifecycle_stage_id
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


    remove_index :application_components, :app_id
    remove_index :application_components, :component_id

    remove_index :application_environments , :app_id
    remove_index :application_environments , :environment_id

    remove_index :apps_business_processes, :app_id
    remove_index :apps_business_processes, :business_process_id

    remove_index :apps_procedures, :app_id
    remove_index :apps_procedures, :procedure_id

    remove_index :apps_properties, :app_id
    remove_index :apps_properties, :property_id

    remove_index :apps_requests, :app_id
    remove_index :apps_requests, :request_id


    remove_index :assets, :owner_id

    remove_index :assigned_apps, :user_id
    remove_index :assigned_apps, :app_id    

    remove_index :assigned_environments, :environment_id
    remove_index :assigned_environments, :assigned_app_id

     remove_index :bladelogic_roles, :bladelogic_user_id  

    remove_index :bladelogic_script_arguments, :script_id

    remove_index :bladelogic_users, :streamdeploy_user_id

    remove_index :budget_line_items , :group_id

    
    # remove_index :budget_line_items, :activity_id #Index is already created in earlier migrations
    
    remove_index :budget_line_items, :user_id

    remove_index :build_contents, :lifecycle_id
    remove_index :build_contents, :query_id

    remove_index :capistrano_script_arguments, :script_id

    remove_index :change_requests, :lifecycle_id
    remove_index :change_requests, :project_server_id
    remove_index :change_requests, :query_id


    remove_index :component_properties, :component_id
    remove_index :component_properties, :property_id

    remove_index :containers, :group_id
    remove_index :containers, :manager_id

    remove_index :development_teams, :team_id
    remove_index :development_teams, :app_id

    remove_index :email_recipients, :request_id
    remove_index :email_recipients, :recipient_id

    remove_index :environment_roles, :environment_id
    remove_index :environment_roles, :user_id

    remove_index :environment_servers, :environment_id
    remove_index :environment_servers, :server_id
    remove_index :environment_servers, :server_aspect_id

    remove_index :environments, :default_server_group_id

    remove_index :installed_components, :application_component_id
    remove_index :installed_components, :application_environment_id
    remove_index :installed_components, :reference_id

    remove_index :integration_csv_columns, :integration_csv_id

    remove_index :integration_csv_data, :integration_csv_column_id

    remove_index :integration_csvs, :lifecycle_id
    remove_index :integration_csvs, :project_server_id
    remove_index :integration_csvs, :user_id

    remove_index :integration_projects, :project_server_id

    remove_index :integration_releases, :integration_project_id

    remove_index :job_runs, :step_id

    remove_index :lifecycle_activities, :lifecycle_id
    remove_index :lifecycle_activities, :activity_id

    remove_index :lifecycle_apps, :lifecycle_id
    remove_index :lifecycle_apps, :app_id

    remove_index :lifecycle_environments, :lifecycle_id
    remove_index :lifecycle_environments, :environment_id
    remove_index :lifecycle_environments, :environment_group_id

    remove_index :lifecycle_members, :app_id
    remove_index :lifecycle_members, :server_id
    remove_index :lifecycle_members, :server_aspect_id
    remove_index :lifecycle_members, :lifecycle_template_id
    remove_index :lifecycle_members, :lifecycle_id
    remove_index :lifecycle_members, :lifecycle_stage_id

    remove_index :lifecycle_stage_dates, :lifecycle_stage_id

    remove_index :lifecycle_stages, :request_template_id
    remove_index :lifecycle_stages, :lifecycle_template_id

    remove_index :lifecycle_teams, :lifecycle_id

    remove_index :lifecycle_wikis, :lifecycle_id  

    remove_index :lifecycles, :lifecycle_template_id
    remove_index :lifecycles, :release_manager_id
    remove_index :lifecycles, :release_id

    remove_index :list_items, :list_id

    remove_index :messages, :sender_id
    remove_index :messages, :request_id

    remove_index :notes, :user_id

    # remove_index :notes, :step_id #Index is already created in earlier migrations

    remove_index :package_template_components, :package_template_item_id
    remove_index :package_template_components, :application_component_id

     remove_index :package_template_items, :component_template_id

    remove_index :package_templates, :app_id

    remove_index :parent_activities, :container_id
    remove_index :parent_activities, :activity_id

    remove_index :preferences, :user_id

    remove_index :property_tasks, :property_id
    remove_index :property_tasks, :task_id

    remove_index :property_values, :property_id
    remove_index :property_values, :value_holder_id

    remove_index :queries, :lifecycle_id
    remove_index :queries, :project_server_id
    remove_index :queries, :last_run_by

    remove_index :query_details, :query_id

    remove_index :recent_activities, :actor_id
    remove_index :recent_activities, :object_id
    remove_index :recent_activities, :indirect_object_id

    remove_index :release_content_items, :lifecycle_id
    remove_index :release_content_items, :integration_project_id
    remove_index :release_content_items, :integration_release_id


    remove_index :release_contents, :lifecycle_id
    remove_index :release_contents, :query_id

    remove_index :request_package_contents, :request_id
    remove_index :request_package_contents, :package_content_id

    remove_index :requests, :environment_id
    remove_index :requests, :environment_group_id
    remove_index :requests, :business_process_id
    remove_index :requests, :deployment_coordinator_id
    remove_index :requests, :requestor_id
    remove_index :requests, :owner_id
    remove_index :requests, :release_id
    remove_index :requests, :category_id
    remove_index :requests, :request_template_id
    remove_index :requests, :activity_id
    remove_index :requests, :lifecycle_member_id
    remove_index :requests, :server_association_id

    remove_index :resource_allocations, :allocated_id

    remove_index :runtime_phases, :phase_id

    remove_index :script_arguments, :script_id

    remove_index :security_answers, :user_id

    remove_index :server_aspects, :parent_id

    remove_index :server_level_properties, :server_level_id
    remove_index :server_level_properties, :property_id            

    remove_index :step_execution_conditions, :referenced_step_id
    remove_index :step_execution_conditions, :property_id  

    remove_index :step_script_arguments, :step_id
    remove_index :step_script_arguments, :script_argument_id 


    # remove_index :steps, :request_id #Index is already created in earlier migrations
    
    remove_index :steps, :app_id            
    remove_index :steps, :parent_id
    remove_index :steps, :procedure_id            
    remove_index :steps, :owner_id
    remove_index :steps, :component_id            
    # remove_index :steps, :script_id #Index is already created in earlier migrations
    remove_index :steps, :task_id            
    remove_index :steps, :category_id
    remove_index :steps, :phase_id            
    remove_index :steps, :runtime_phase_id            
    remove_index :steps, :package_template_id                  
    remove_index :steps, :change_request_id


    remove_index :teams_groups, :group_id                
    remove_index :teams_groups, :team_id    

    remove_index :teams_roles, :team_id    
    remove_index :teams_roles, :app_id    
    remove_index :teams_roles, :user_id    

    remove_index :teams_users, :team_id    
    remove_index :teams_users, :user_id    

    remove_index :temporary_property_values, :step_id        
    remove_index :temporary_property_values, :property_id        
    remove_index :temporary_property_values, :original_value_holder_id

    remove_index :user_apps, :user_id            
    remove_index :user_apps, :app_id 

    remove_index :user_groups, :user_id
    remove_index :user_groups, :group_id   

    remove_index :workstreams, :resource_id
    remove_index :workstreams, :activity_id
    

    remove_index :temporary_budget_line_items, :name => 'tbli_group_id'
    remove_index :temporary_budget_line_items, :name => 'tbli_activity_id'
    remove_index :temporary_budget_line_items, :name => 'tbli_budget_line_item_id'
    remove_index :temporary_budget_line_items, :name => 'tbli_user_id'
            
    remove_index :server_aspects, :name => 'sa_server_level_id'
            
    remove_index :server_aspect_groups, :name => 'sag_server_level_id' 
        
    remove_index :servers_steps, :server_id
    remove_index :servers_steps, :step_id
             
    remove_index :request_templates, :team_id
    remove_index :request_templates, :parent_id
    
  end
end
