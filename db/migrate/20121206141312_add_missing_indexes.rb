class AddMissingIndexes < ActiveRecord::Migration
  def self.up
    add_index :plan_stage_statuses, :plan_stage_id
    add_index :service_now_data, :project_server_id
    add_index :notes, [:object_id, :object_type]
    add_index :step_holders, :step_id
    add_index :step_holders, :request_id
    add_index :step_holders, :change_request_id
    add_index :steps_release_content_items, :step_id
    add_index :steps_release_content_items, :release_content_item_id
    add_index :server_aspects, [:parent_id, :parent_type]
    add_index :property_values, [:value_holder_id, :value_holder_type]
    add_index :version_tags, :app_id
    add_index :version_tags, :app_env_id
    add_index :version_tags, :installed_component_id
    add_index :activity_logs, :step_id
    add_index :step_script_arguments, [:script_argument_id, :script_argument_type], :name => 'step_script_arguments_said_sat'
    add_index :application_component_mappings, :application_component_id, :name => 'app_component_mappings_acid'
    add_index :application_component_mappings, :project_server_id
    add_index :application_component_mappings, :script_id
    add_index :recent_activities, [:actor_id, :actor_type]
    add_index :recent_activities, [:object_id, :object_type]
    add_index :recent_activities, [:indirect_object_id, :indirect_object_type], :name => 'recent_act_indobjid_indobjtype'
    add_index :plan_env_app_dates, :plan_id
    add_index :plan_env_app_dates, :environment_id
    add_index :plan_env_app_dates, :app_id
    add_index :plans, :project_server_id
    add_index :temporary_property_values, [:original_value_holder_id, :original_value_holder_type], :name => 'tmppropval_orgvhid_orgvhtype'
    add_index :plan_members, :run_id
    add_index :requests, [:server_association_id, :server_association_type], :name => 'req_svrassocid_svrassoctype'
    add_index :activity_attribute_values, [:value_object_id, :value_object_type], :name => 'actattrval_valobjid_valobjtype'
    add_index :plan_teams, :team_id
    add_index :installed_components, :default_server_group_id
    add_index :tickets, :app_id
    add_index :email_recipients, [:recipient_id, :recipient_type]
    add_index :resource_allocations, [:allocated_id, :allocated_type]
    add_index :package_template_items, :package_template_id
    add_index :steps, [:owner_id, :owner_type]
    add_index :steps, :installed_component_id
    add_index :steps, :version_tag_id
  end

  def self.down
    remove_index :plan_stage_statuses, :plan_stage_id
    remove_index :service_now_data, :project_server_id
    remove_index :notes, :column => [:object_id, :object_type]
    remove_index :step_holders, :step_id
    remove_index :step_holders, :request_id
    remove_index :step_holders, :change_request_id
    remove_index :steps_release_content_items, :step_id
    remove_index :steps_release_content_items, :release_content_item_id
    remove_index :server_aspects, :column => [:parent_id, :parent_type]
    remove_index :property_values, :column => [:value_holder_id, :value_holder_type]
    remove_index :version_tags, :app_id
    remove_index :version_tags, :app_env_id
    remove_index :version_tags, :installed_component_id
    remove_index :activity_logs, :step_id
    remove_index :step_script_arguments, :column => [:script_argument_id, :script_argument_type], :name => 'step_script_arguments_said_sat'
    remove_index :application_component_mappings, :application_component_id, :name => 'app_component_mappings_acid'
    remove_index :application_component_mappings, :project_server_id
    remove_index :application_component_mappings, :script_id
    remove_index :recent_activities, :column => [:actor_id, :actor_type]
    remove_index :recent_activities, :column => [:object_id, :object_type]
    remove_index :recent_activities, :column => [:indirect_object_id, :indirect_object_type], :name => 'recent_act_indobjid_indobjtype'
    remove_index :plan_env_app_dates, :plan_id
    remove_index :plan_env_app_dates, :environment_id
    remove_index :plan_env_app_dates, :app_id
    remove_index :plans, :project_server_id
    remove_index :temporary_property_values, :column => [:original_value_holder_id, :original_value_holder_type], :name => 'tmppropval_orgvhid_orgvhtype'
    remove_index :plan_members, :run_id
    remove_index :requests, :column => [:server_association_id, :server_association_type], :name => 'req_svrassocid_svrassoctype'
    remove_index :activity_attribute_values, :column => [:value_object_id, :value_object_type], :name => 'actattrval_valobjid_valobjtype'
    remove_index :plan_teams, :team_id
    remove_index :installed_components, :default_server_group_id
    remove_index :tickets, :app_id
    remove_index :email_recipients, :column => [:recipient_id, :recipient_type]
    remove_index :resource_allocations, :column => [:allocated_id, :allocated_type]
    remove_index :package_template_items, :package_template_id
    remove_index :steps, :column => [:owner_id, :owner_type]
    remove_index :steps, :installed_component_id
    remove_index :steps, :version_tag_id
  end
end
