################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# This file encompasses all schema changes from 2008- 4/5/2010
# 
class Comprehensive < ActiveRecord::Migration
  def self.up

    create_table "activities" do |t|
      t.string   "name"
      t.integer  "app_id"
      t.integer  "release_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "user_id"
      t.datetime "planned_start"
      t.datetime "planned_end"
      t.text     "shortcuts"
      t.integer  "lifecycle_stage_id"
      t.integer  "activity_category_id"
      t.string   "health",               :default => "green"
      t.integer  "current_phase_id"
      t.datetime "projected_finish_at"
      t.date     "last_phase_end_on"
      t.integer  "leading_group_id"
      t.string   "status"
      t.text     "problem_opportunity"
      t.string   "budget_category"
      t.integer  "manager_id"
      t.text     "goal"
      t.text     "blockers"
      t.text     "theme"
      t.boolean  "cio_list",             :default => false,   :null => false
      t.integer  "budget"
      t.text     "phase_start_dates"
      t.text     "service_description"
    end

    create_table "activities_lifecycle_members", :id => false do |t|
      t.integer "activity_id",         :null => false
      t.integer "lifecycle_member_id", :null => false
    end

    create_table "activity_attribute_values" do |t|
      t.integer  "activity_id",           :null => false
      t.integer  "activity_attribute_id", :null => false
      t.text     "value"
      t.integer  "value_object_id"
      t.string   "value_object_type"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "activity_attributes" do |t|
      t.string   "name",                                :null => false
      t.boolean  "required",         :default => false, :null => false
      t.string   "input_type"
      t.text     "attribute_values"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "from_system",      :default => false, :null => false
      t.string   "type"
      t.string   "field"
      t.integer  "list_id"
    end

    create_table "activity_categories" do |t|
      t.string   "name",                                  :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "position"
      t.boolean  "request_compatible", :default => false, :null => false
    end

    create_table "activity_creation_attributes" do |t|
      t.integer  "activity_category_id"
      t.integer  "activity_attribute_id"
      t.boolean  "disabled",              :default => false, :null => false
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "activity_deliverables" do |t|
      t.integer  "activity_id",           :null => false
      t.integer  "activity_phase_id"
      t.string   "name",                  :null => false
      t.text     "description"
      t.date     "projected_delivery_on"
      t.date     "delivered_on"
      t.text     "highlights"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "activity_index_columns" do |t|
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "activity_category_id",      :null => false
      t.string   "activity_attribute_column"
    end

    create_table "activity_logs" do |t|
      t.integer  "request_id",      :null => false
      t.integer  "user_id",         :null => false
      t.text     "activity",        :null => false
      t.datetime "created_at"
      t.integer  "usec_created_at"
    end

    add_index "activity_logs", ["request_id"], :name => "logs_by_request"

    create_table "activity_notes" do |t|
      t.integer  "activity_id",                   :null => false
      t.text     "contents",                      :null => false
      t.integer  "user_id",                       :null => false
      t.boolean  "generic",     :default => true, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "activity_phases" do |t|
      t.string   "name",                 :null => false
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "activity_category_id", :null => false
    end

    create_table "activity_tab_attributes" do |t|
      t.integer  "activity_tab_id",                          :null => false
      t.integer  "activity_attribute_id",                    :null => false
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "disabled",              :default => false, :null => false
    end

    create_table "activity_tabs" do |t|
      t.string   "name",                                    :null => false
      t.integer  "activity_category_id",                    :null => false
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "read_only",            :default => false, :null => false
    end

    create_table "application_components" do |t|
      t.integer  "app_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "component_id"
      t.integer  "position"
      t.boolean  "different_level_from_previous", :default => true, :null => false
    end

    create_table "application_environments" do |t|
      t.integer  "app_id"
      t.integer  "environment_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "position"
      t.boolean  "different_level_from_previous", :default => true, :null => false
    end

    create_table "apps" do |t|
      t.string   "name",                          :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "active",     :default => true,  :null => false
      t.boolean  "default",    :default => false, :null => false
    end

    create_table "apps_procedures", :id => false do |t|
      t.integer "app_id"
      t.integer "procedure_id"
    end

    create_table "apps_properties", :id => false do |t|
      t.integer "app_id",      :null => false
      t.integer "property_id", :null => false
    end

    create_table "assets" do |t|
      t.integer "owner_id"
      t.string  "content_type"
      t.string  "filename"
      t.integer "size"
      t.integer "parent_id"
      t.string  "thumbnail"
      t.integer "width"
      t.integer "height"
      t.string  "owner_type"
    end

    create_table "audits" do |t|
      t.integer  "auditable_id"
      t.string   "auditable_type"
      t.integer  "user_id"
      t.string   "user_type"
      t.string   "username"
      t.string   "action"
      t.text     "changes"
      t.integer  "version",        :default => 0
      t.datetime "created_at"
    end

    add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
    add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
    add_index "audits", ["user_id", "user_type"], :name => "user_index"

    create_table "bladelogic_roles" do |t|
      t.integer  "bladelogic_user_id", :null => false
      t.string   "name",               :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "bladelogic_script_arguments" do |t|
      t.integer  "script_id"
      t.string   "argument"
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "bladelogic_scripts" do |t|
      t.string   "name"
      t.string   "description"
      t.text     "content"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "authentication"
    end

    create_table "bladelogic_users" do |t|
      t.string   "username",             :null => false
      t.integer  "streamdeploy_user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "default_role"
    end

    create_table "budget_import_logs" do |t|
      t.string   "table"
      t.integer  "table_id"
      t.integer  "user_id"
      t.string   "field"
      t.string   "value"
      t.string   "value_old"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "budget_line_items" do |t|
      t.integer  "group_id"
      t.integer  "activity_id"
      t.text     "description"
      t.integer  "projected_cost"
      t.string   "location"
      t.string   "cost_type"
      t.string   "budget_item_category"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "approval_status"
      t.string   "budget_year"
      t.string   "comment"
      t.string   "po_number"
      t.string   "sap_refences"
      t.string   "ion_number"
      t.string   "corporate_it_category"
      t.integer  "bottom_up_forecast"
      t.integer  "yef_2010"
      t.integer  "forecast_jan_2010"
      t.integer  "forecast_feb_2010"
      t.integer  "forecast_mar_2010"
      t.integer  "forecast_apr_2010"
      t.integer  "forecast_mei_2010"
      t.integer  "forecast_jun_2010"
      t.integer  "forecast_jul_2010"
      t.integer  "forecast_aug_2010"
      t.integer  "forecast_sep_2010"
      t.integer  "forecast_oct_2010"
      t.integer  "forecast_nov_2010"
      t.integer  "forecast_dec_2010"
      t.integer  "ytdas_2010"
      t.integer  "actuals_jan_2010"
      t.integer  "actuals_feb_2010"
      t.integer  "actuals_mar_2010"
      t.integer  "actuals_apr_2010"
      t.integer  "actuals_mei_2010"
      t.integer  "actuals_jun_2010"
      t.integer  "actuals_jul_2010"
      t.integer  "actuals_aug_2010"
      t.integer  "actuals_sep_2010"
      t.integer  "actuals_oct_2010"
      t.integer  "actuals_nov_2010"
      t.integer  "actuals_dec_2010"
      t.integer  "le0_total_2010"
      t.integer  "le2_total_2010"
      t.integer  "le3_total_2010"
      t.integer  "ytd_lex_2010"
      t.integer  "lex_jan_2010"
      t.integer  "lex_feb_2010"
      t.integer  "lex_mar_2010"
      t.integer  "lex_apr_2010"
      t.integer  "lex_mei_2010"
      t.integer  "lex_jun_2010"
      t.integer  "lex_jul_2010"
      t.integer  "lex_aug_2010"
      t.integer  "lex_sep_2010"
      t.integer  "lex_oct_2010"
      t.integer  "lex_nov_2010"
      t.integer  "lex_dec_2010"
      t.boolean  "is_deleted",              :default => false
      t.integer  "user_id"
      t.integer  "car_number"
      t.integer  "responsible_cost_center"
      t.integer  "prioritized_bottom_up"
    end

    add_index "budget_line_items", ["activity_id"], :name => "budget_line_items_activity_id"

    create_table "business_processes" do |t|
      t.string   "name",                         :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "active",     :default => true, :null => false
    end

    create_table "capistrano_script_arguments" do |t|
      t.integer  "script_id"
      t.string   "argument"
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "capistrano_scripts" do |t|
      t.string   "name"
      t.string   "description"
      t.text     "content"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "categories" do |t|
      t.string   "categorized_type"
      t.string   "name"
      t.string   "associated_events"
      t.boolean  "active",            :default => true, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "component_properties" do |t|
      t.integer "component_id"
      t.integer "property_id"
      t.integer "position"
    end

    create_table "components" do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "active",     :default => true
    end

    create_table "containers" do |t|
      t.string   "container_type"
      t.integer  "group_id"
      t.integer  "manager_id"
      t.text     "description"
      t.text     "objective"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "active",         :default => true, :null => false
      t.string   "name"
    end

    create_table "email_recipients" do |t|
      t.integer  "request_id"
      t.integer  "recipient_id"
      t.string   "recipient_type"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "environment_servers" do |t|
      t.integer  "environment_id"
      t.integer  "server_id"
      t.boolean  "default_server",   :default => false, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "server_aspect_id"
    end

    create_table "environments" do |t|
      t.string   "name",                                       :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "active",                  :default => true,  :null => false
      t.integer  "default_server_group_id"
      t.boolean  "default",                 :default => false, :null => false
    end

    create_table "environments_server_groups", :id => false do |t|
      t.integer "environment_id"
      t.integer "server_group_id"
    end

    create_table "group_management", :id => false do |t|
      t.integer "manager_id"
      t.integer "group_id"
    end

    create_table "groups" do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "email"
      t.integer  "position"
    end

    create_table "icsags", :id => false do |t|
      t.integer "installed_component_id"
      t.integer "server_aspect_group_id"
    end

    create_table "icsas", :id => false do |t|
      t.integer "installed_component_id"
      t.integer "server_aspect_id"
    end

    create_table "installed_components" do |t|
      t.integer  "application_component_id"
      t.integer  "application_environment_id"
      t.string   "location"
      t.string   "version"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "default_server_group_id"
      t.integer  "reference_id"
    end

    create_table "installed_components_servers", :id => false do |t|
      t.integer "installed_component_id", :null => false
      t.integer "server_id",              :null => false
    end

    create_table "lifecycle_members" do |t|
      t.integer  "app_id"
      t.integer  "lifecycle_stage_id"
      t.integer  "lifecycle_stage_status_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "lifecycle_id"
      t.integer  "lifecycle_template_id",     :null => false
      t.integer  "server_id"
      t.integer  "server_aspect_id"
    end

    create_table "lifecycle_stage_statuses" do |t|
      t.string   "name"
      t.integer  "lifecycle_stage_id", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "position"
    end

    create_table "lifecycle_stages" do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "lifecycle_template_id", :null => false
      t.integer  "position"
      t.integer  "request_template_id"
    end

    create_table "lifecycle_templates" do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "lifecycles" do |t|
      t.integer  "lifecycle_template_id", :null => false
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "list_items" do |t|
      t.integer  "list_id"
      t.string   "value_text"
      t.integer  "value_num"
      t.integer  "last_modified_by_id"
      t.boolean  "is_active",           :default => true
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "lists" do |t|
      t.string   "name"
      t.integer  "created_by_id"
      t.boolean  "is_text"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "is_active",     :default => true
    end

    create_table "messages" do |t|
      t.integer  "sender_id",  :null => false
      t.integer  "request_id", :null => false
      t.string   "subject"
      t.text     "body"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "notes" do |t|
      t.integer  "user_id"
      t.integer  "step_id"
      t.text     "content"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "package_contents" do |t|
      t.string   "name"
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "abbreviation"
    end

    create_table "parent_activities" do |t|
      t.integer  "container_id"
      t.integer  "activity_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "parent_activities", ["activity_id", "container_id"], :name => "parent_activities_aid_cid"

    create_table "phases" do |t|
      t.string   "name"
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "procedures" do |t|
      t.string   "name"
      t.text     "description"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "properties" do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "active",        :default => true, :null => false
      t.text     "default_value"
    end

    create_table "properties_servers", :id => false do |t|
      t.integer "property_id", :null => false
      t.integer "server_id",   :null => false
    end

    create_table "property_tasks" do |t|
      t.integer  "property_id"
      t.integer  "task_id"
      t.boolean  "entry_during_step_execution", :default => false, :null => false
      t.boolean  "entry_during_step_creation",  :default => false, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "property_values" do |t|
      t.string   "value"
      t.integer  "value_holder_id"
      t.integer  "property_id"
      t.datetime "created_at"
      t.datetime "deleted_at"
      t.string   "value_holder_type", :null => false
    end

    add_index "property_values", ["property_id", "value_holder_id"], :name => "pvs_pid_icid"

    create_table "releases" do |t|
      t.string   "name",                         :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "active",     :default => true, :null => false
      t.integer  "position"
    end

    create_table "request_package_contents" do |t|
      t.integer  "request_id"
      t.integer  "package_content_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "request_templates" do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "recur_time"
    end

    create_table "requests" do |t|
      t.integer  "business_process_id"
      t.integer  "app_id"
      t.integer  "environment_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "scheduled_at"
      t.datetime "target_completion_at"
      t.text     "notes"
      t.boolean  "notify_on_request_start",       :default => false, :null => false
      t.integer  "deployment_coordinator_id"
      t.integer  "release_id"
      t.string   "aasm_state"
      t.datetime "completed_at"
      t.datetime "started_at"
      t.binary   "frozen_app"
      t.binary   "frozen_environment"
      t.binary   "frozen_business_process"
      t.binary   "frozen_deployment_coordinator"
      t.binary   "frozen_release"
      t.integer  "category_id"
      t.integer  "request_template_id"
      t.boolean  "notify_on_request_complete",    :default => false, :null => false
      t.boolean  "notify_on_step_complete",       :default => false, :null => false
      t.boolean  "notify_on_step_start",          :default => false, :null => false
      t.string   "additional_email_addresses"
      t.datetime "planned_at"
      t.datetime "deleted_at"
      t.boolean  "notify_on_request_hold",        :default => false, :null => false
      t.boolean  "notify_on_step_block",          :default => false, :null => false
      t.string   "name"
      t.text     "description"
      t.string   "estimate"
      t.integer  "requestor_id"
      t.binary   "frozen_requestor"
      t.integer  "activity_id"
      t.boolean  "auto_start",                    :default => false, :null => false
      t.text     "wiki_url"
      t.integer  "lifecycle_member_id"
      t.integer  "server_association_id"
      t.string   "server_association_type"
      t.integer  "owner_id"
      t.boolean  "rescheduled"
      t.boolean  "promotion",                     :default => false
    end

    create_table "resource_allocations" do |t|
      t.integer  "allocated_id",                    :null => false
      t.string   "allocated_type",                  :null => false
      t.integer  "allocation",     :default => 100, :null => false
      t.integer  "year",                            :null => false
      t.integer  "month",                           :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "runtime_phases" do |t|
      t.integer  "phase_id"
      t.string   "name"
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "sagsas", :id => false do |t|
      t.integer "server_aspect_group_id"
      t.integer "server_aspect_id"
    end

    create_table "satpms" do |t|
      t.integer  "script_argument_id"
      t.string   "script_argument_type"
      t.integer  "property_id"
      t.integer  "value_holder_id",      :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "value_holder_type",    :null => false
    end

    create_table "server_aspect_groups" do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "server_level_id"
    end

    create_table "server_aspects" do |t|
      t.integer  "parent_id"
      t.string   "parent_type"
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "server_level_id"
      t.text     "description"
    end

    create_table "server_aspects_steps", :id => false do |t|
      t.integer "server_aspect_id"
      t.integer "step_id"
    end

    create_table "server_groups" do |t|
      t.string   "name"
      t.text     "description"
      t.boolean  "active",      :default => true, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "server_groups_servers", :id => false do |t|
      t.integer "server_group_id"
      t.integer "server_id"
    end

    create_table "server_groups_steps", :id => false do |t|
      t.integer "server_group_id"
      t.integer "step_id"
    end

    create_table "server_level_properties" do |t|
      t.integer  "server_level_id", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "property_id",     :null => false
    end

    create_table "server_levels" do |t|
      t.text     "description"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "position"
      t.string   "name"
    end

    create_table "servers" do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "active",     :default => true, :null => false
    end

    create_table "servers_steps", :id => false do |t|
      t.integer "server_id"
      t.integer "step_id"
    end

    create_table "step_execution_conditions" do |t|
      t.integer  "step_id"
      t.integer  "referenced_step_id"
      t.integer  "property_id"
      t.string   "value"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "runtime_phase_id"
    end

    create_table "step_script_arguments" do |t|
      t.integer  "step_id"
      t.integer  "script_argument_id"
      t.string   "value"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "script_argument_type"
    end

    create_table "steps" do |t|
      t.integer  "position"
      t.integer  "request_id"
      t.integer  "component_id"
      t.integer  "owner_id"
      t.string   "component_version"
      t.datetime "complete_by"
      t.boolean  "different_level_from_previous", :default => true,  :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "estimate"
      t.string   "location_detail"
      t.string   "aasm_state"
      t.datetime "work_started_at"
      t.datetime "work_finished_at"
      t.boolean  "manual",                        :default => true,  :null => false
      t.integer  "task_id"
      t.text     "description"
      t.string   "bladelogic_password"
      t.string   "bladelogic_role"
      t.binary   "frozen_owner"
      t.binary   "frozen_component"
      t.binary   "frozen_task"
      t.string   "owner_type"
      t.integer  "category_id"
      t.integer  "procedure_id"
      t.integer  "parent_id"
      t.datetime "ready_at"
      t.string   "name"
      t.datetime "start_by"
      t.boolean  "procedure",                     :default => false, :null => false
      t.integer  "phase_id"
      t.boolean  "should_execute",                :default => true,  :null => false
      t.boolean  "execute_anytime",               :default => false, :null => false
      t.integer  "runtime_phase_id"
      t.integer  "script_id"
      t.string   "script_type"
      t.binary   "frozen_script"
    end

    add_index "steps", ["request_id"], :name => "steps_request_id"

    create_table "system_settings" do |t|
      t.string "name",  :null => false
      t.text   "value", :null => false
    end

    add_index "system_settings", ["name"], :name => "index_system_settings_on_name", :unique => true

    create_table "tasks" do |t|
      t.string   "name",                         :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "active",     :default => true, :null => false
      t.integer  "position"
    end

    create_table "temporary_budget_line_items" do |t|
      t.integer  "group_id"
      t.integer  "activity_id"
      t.text     "description"
      t.integer  "projected_cost"
      t.string   "location"
      t.string   "cost_type"
      t.string   "budget_item_category"
      t.string   "status"
      t.string   "operation"
      t.integer  "budget_line_item_id"
      t.string   "import_session"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "approval_status"
      t.string   "comment"
      t.string   "po_number"
      t.string   "sap_refences"
      t.string   "ion_number"
      t.string   "corporate_it_category"
      t.integer  "bottom_up_forecast"
      t.integer  "yef_2010"
      t.integer  "forecast_jan_2010"
      t.integer  "forecast_feb_2010"
      t.integer  "forecast_mar_2010"
      t.integer  "forecast_apr_2010"
      t.integer  "forecast_mei_2010"
      t.integer  "forecast_jun_2010"
      t.integer  "forecast_jul_2010"
      t.integer  "forecast_aug_2010"
      t.integer  "forecast_sep_2010"
      t.integer  "forecast_oct_2010"
      t.integer  "forecast_nov_2010"
      t.integer  "forecast_dec_2010"
      t.integer  "ytdas_2010"
      t.integer  "actuals_jan_2010"
      t.integer  "actuals_feb_2010"
      t.integer  "actuals_mar_2010"
      t.integer  "actuals_apr_2010"
      t.integer  "actuals_mei_2010"
      t.integer  "actuals_jun_2010"
      t.integer  "actuals_jul_2010"
      t.integer  "actuals_aug_2010"
      t.integer  "actuals_sep_2010"
      t.integer  "actuals_oct_2010"
      t.integer  "actuals_nov_2010"
      t.integer  "actuals_dec_2010"
      t.integer  "le0_total_2010"
      t.integer  "le2_total_2010"
      t.integer  "le3_total_2010"
      t.integer  "ytd_lex_2010"
      t.integer  "lex_jan_2010"
      t.integer  "lex_feb_2010"
      t.integer  "lex_mar_2010"
      t.integer  "lex_apr_2010"
      t.integer  "lex_mei_2010"
      t.integer  "lex_jun_2010"
      t.integer  "lex_jul_2010"
      t.integer  "lex_aug_2010"
      t.integer  "lex_sep_2010"
      t.integer  "lex_oct_2010"
      t.integer  "lex_nov_2010"
      t.integer  "lex_dec_2010"
      t.integer  "user_id"
      t.integer  "car_number"
      t.integer  "responsible_cost_center"
      t.integer  "prioritized_bottom_up"
      t.string   "budget_year"
    end

    create_table "temporary_property_values" do |t|
      t.integer  "property_id",                :null => false
      t.integer  "step_id",                    :null => false
      t.integer  "original_value_holder_id",   :null => false
      t.string   "original_value_holder_type", :null => false
      t.string   "value"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "transaction_logs" do |t|
      t.integer  "year"
      t.integer  "month"
      t.string   "file_name"
      t.text     "content"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "transaction_logs", ["file_name"], :name => "index_t_logs_on_file_name"
    add_index "transaction_logs", ["month"], :name => "index_t_logs_on_month"
    add_index "transaction_logs", ["year"], :name => "index_t_logs_on_year"

    create_table "user_groups" do |t|
      t.integer  "user_id"
      t.integer  "group_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "users" do |t|
      t.string   "login"
      t.string   "email"
      t.string   "first_name"
      t.string   "last_name"
      t.string   "crypted_password",          :limit => 40
      t.string   "salt",                      :limit => 40
      t.string   "remember_token"
      t.datetime "remember_token_expires_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "admin",                                   :default => false
      t.boolean  "active",                                  :default => true,        :null => false
      t.text     "roles"
      t.string   "employment_type",                         :default => "permanent", :null => false
      t.string   "location"
      t.integer  "max_allocation",                          :default => 100,         :null => false
      t.boolean  "system_user",                             :default => true,        :null => false
      t.string   "type"
      t.boolean  "root",                                    :default => false,       :null => false
    end

    create_table "workstreams" do |t|
      t.integer  "resource_id",   :null => false
      t.integer  "activity_id",   :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "activity_role"
    end
    
  end
  
  def self.down
    # Drop the database
  end
  

end
