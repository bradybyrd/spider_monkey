# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20141017200955) do

  create_table "activities", :force => true do |t|
    t.string   "name"
    t.integer  "app_id"
    t.integer  "release_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.datetime "planned_start"
    t.datetime "planned_end"
    t.text     "shortcuts"
    t.integer  "plan_stage_id"
    t.integer  "activity_category_id"
    t.string   "health",                    :default => "green"
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
    t.boolean  "cio_list",                  :default => false,   :null => false
    t.integer  "budget"
    t.text     "phase_start_dates"
    t.text     "service_description"
    t.string   "project_mgt_approach"
    t.datetime "estimated_start_for_spend"
  end

  add_index "activities", ["activity_category_id"], :name => "index_activities_on_activity_category_id"
  add_index "activities", ["app_id"], :name => "index_activities_on_app_id"
  add_index "activities", ["current_phase_id"], :name => "index_activities_on_current_phase_id"
  add_index "activities", ["leading_group_id"], :name => "index_activities_on_leading_group_id"
  add_index "activities", ["manager_id"], :name => "index_activities_on_manager_id"
  add_index "activities", ["plan_stage_id"], :name => "index_activities_on_plan_stage_id"
  add_index "activities", ["release_id"], :name => "index_activities_on_release_id"
  add_index "activities", ["user_id"], :name => "index_activities_on_user_id"

  create_table "activity_attribute_values", :force => true do |t|
    t.integer  "activity_id"
    t.integer  "activity_attribute_id", :null => false
    t.text     "value"
    t.integer  "value_object_id"
    t.string   "value_object_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activity_attribute_values", ["activity_attribute_id"], :name => "index_activity_attribute_values_on_activity_attribute_id"
  add_index "activity_attribute_values", ["activity_id"], :name => "index_activity_attribute_values_on_activity_id"
  add_index "activity_attribute_values", ["value_object_id", "value_object_type"], :name => "actattrval_valobjid_valobjtype"
  add_index "activity_attribute_values", ["value_object_id"], :name => "index_activity_attribute_values_on_value_object_id"

  create_table "activity_attributes", :force => true do |t|
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

  add_index "activity_attributes", ["id", "type"], :name => "index_activity_attributes_on_id_and_type"
  add_index "activity_attributes", ["list_id"], :name => "index_activity_attributes_on_list_id"

  create_table "activity_categories", :force => true do |t|
    t.string   "name",                                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.boolean  "request_compatible", :default => false, :null => false
  end

  create_table "activity_creation_attributes", :force => true do |t|
    t.integer  "activity_category_id"
    t.integer  "activity_attribute_id"
    t.boolean  "disabled",              :default => false, :null => false
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activity_creation_attributes", ["activity_attribute_id"], :name => "index_activity_creation_attributes_on_activity_attribute_id"
  add_index "activity_creation_attributes", ["activity_category_id"], :name => "index_activity_creation_attributes_on_activity_category_id"

  create_table "activity_deliverables", :force => true do |t|
    t.integer  "activity_id",                              :null => false
    t.integer  "activity_phase_id"
    t.string   "name",                                     :null => false
    t.text     "description"
    t.date     "projected_delivery_on"
    t.date     "delivered_on"
    t.text     "highlights"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "release_deployment",    :default => false
    t.integer  "deployment_contact_id"
  end

  add_index "activity_deliverables", ["activity_id"], :name => "index_activity_deliverables_on_activity_id"
  add_index "activity_deliverables", ["activity_phase_id"], :name => "index_activity_deliverables_on_activity_phase_id"
  add_index "activity_deliverables", ["deployment_contact_id"], :name => "index_activity_deliverables_on_deployment_contact_id"

  create_table "activity_index_columns", :force => true do |t|
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "activity_category_id",      :null => false
    t.string   "activity_attribute_column"
  end

  add_index "activity_index_columns", ["activity_category_id"], :name => "index_activity_index_columns_on_activity_category_id"

  create_table "activity_logs", :force => true do |t|
    t.integer  "request_id",      :null => false
    t.integer  "user_id",         :null => false
    t.text     "activity",        :null => false
    t.datetime "created_at"
    t.integer  "usec_created_at"
    t.integer  "step_id"
    t.string   "type"
  end

  add_index "activity_logs", ["request_id"], :name => "logs_by_request"
  add_index "activity_logs", ["step_id"], :name => "index_activity_logs_on_step_id"
  add_index "activity_logs", ["user_id"], :name => "index_activity_logs_on_user_id"

  create_table "activity_notes", :force => true do |t|
    t.integer  "activity_id",                   :null => false
    t.text     "contents",                      :null => false
    t.integer  "user_id",                       :null => false
    t.boolean  "generic",     :default => true, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activity_notes", ["activity_id"], :name => "index_activity_notes_on_activity_id"
  add_index "activity_notes", ["user_id"], :name => "index_activity_notes_on_user_id"

  create_table "activity_phases", :force => true do |t|
    t.string   "name",                 :null => false
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "activity_category_id", :null => false
  end

  add_index "activity_phases", ["activity_category_id"], :name => "index_activity_phases_on_activity_category_id"

  create_table "activity_tab_attributes", :force => true do |t|
    t.integer  "activity_tab_id",                          :null => false
    t.integer  "activity_attribute_id",                    :null => false
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "disabled",              :default => false, :null => false
  end

  add_index "activity_tab_attributes", ["activity_attribute_id"], :name => "index_activity_tab_attributes_on_activity_attribute_id"
  add_index "activity_tab_attributes", ["activity_tab_id"], :name => "index_activity_tab_attributes_on_activity_tab_id"

  create_table "activity_tabs", :force => true do |t|
    t.string   "name",                                    :null => false
    t.integer  "activity_category_id",                    :null => false
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "read_only",            :default => false, :null => false
  end

  add_index "activity_tabs", ["activity_category_id"], :name => "index_activity_tabs_on_activity_category_id"

  create_table "application_component_mappings", :force => true do |t|
    t.integer  "application_component_id"
    t.integer  "project_server_id"
    t.integer  "script_id"
    t.text     "data"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "application_component_mappings", ["application_component_id"], :name => "app_component_mappings_acid"
  add_index "application_component_mappings", ["project_server_id"], :name => "index_application_component_mappings_on_project_server_id"
  add_index "application_component_mappings", ["script_id"], :name => "index_application_component_mappings_on_script_id"

  create_table "application_components", :force => true do |t|
    t.integer  "app_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "component_id"
    t.integer  "position"
    t.boolean  "different_level_from_previous", :default => true, :null => false
  end

  add_index "application_components", ["app_id"], :name => "index_application_components_on_app_id"
  add_index "application_components", ["component_id"], :name => "index_application_components_on_component_id"

  create_table "application_environments", :force => true do |t|
    t.integer  "app_id"
    t.integer  "environment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.boolean  "different_level_from_previous", :default => true, :null => false
    t.integer  "environment_group_id"
    t.integer  "version_tag_id"
  end

  add_index "application_environments", ["app_id"], :name => "index_application_environments_on_app_id"
  add_index "application_environments", ["environment_id"], :name => "index_application_environments_on_environment_id"

  create_table "application_packages", :force => true do |t|
    t.integer  "app_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "package_id"
    t.integer  "position"
    t.boolean  "different_level_from_previous", :default => true, :null => false
  end

  create_table "apps", :force => true do |t|
    t.string   "name",                                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",              :default => true,  :null => false
    t.boolean  "default",             :default => false, :null => false
    t.string   "app_version"
    t.boolean  "strict_plan_control", :default => false, :null => false
    t.boolean  "a_sorting_envs",      :default => false, :null => false
    t.boolean  "a_sorting_comps",     :default => false, :null => false
  end

  add_index "apps", ["strict_plan_control"], :name => "I_A_STRICT_PC"

  create_table "apps_business_processes", :force => true do |t|
    t.integer  "app_id"
    t.integer  "business_process_id"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "apps_business_processes", ["app_id"], :name => "index_apps_business_processes_on_app_id"
  add_index "apps_business_processes", ["business_process_id"], :name => "index_apps_business_processes_on_business_process_id"

  create_table "apps_procedures", :id => false, :force => true do |t|
    t.integer "app_id"
    t.integer "procedure_id"
  end

  add_index "apps_procedures", ["app_id"], :name => "index_apps_procedures_on_app_id"
  add_index "apps_procedures", ["procedure_id"], :name => "index_apps_procedures_on_procedure_id"

  create_table "apps_properties", :id => false, :force => true do |t|
    t.integer "app_id",      :null => false
    t.integer "property_id", :null => false
  end

  add_index "apps_properties", ["app_id"], :name => "index_apps_properties_on_app_id"
  add_index "apps_properties", ["property_id"], :name => "index_apps_properties_on_property_id"

  create_table "apps_requests", :force => true do |t|
    t.integer  "request_id"
    t.integer  "app_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.binary   "frozen_app"
  end

  add_index "apps_requests", ["app_id"], :name => "index_apps_requests_on_app_id"
  add_index "apps_requests", ["request_id"], :name => "index_apps_requests_on_request_id"

  create_table "assigned_apps", :force => true do |t|
    t.integer  "user_id"
    t.integer  "app_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "team_id"
  end

  add_index "assigned_apps", ["app_id", "team_id"], :name => "index_assigned_apps_on_app_id_and_team_id"
  add_index "assigned_apps", ["app_id"], :name => "index_assigned_apps_on_app_id"
  add_index "assigned_apps", ["team_id", "user_id"], :name => "index_assigned_apps_on_team_id_and_user_id"
  add_index "assigned_apps", ["team_id"], :name => "index_assigned_apps_on_team_id"
  add_index "assigned_apps", ["user_id"], :name => "index_assigned_apps_on_user_id"

  create_table "assigned_environments", :force => true do |t|
    t.integer  "assigned_app_id"
    t.integer  "environment_id"
    t.string   "role"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "assigned_environments", ["assigned_app_id"], :name => "index_assigned_environments_on_assigned_app_id"
  add_index "assigned_environments", ["environment_id"], :name => "index_assigned_environments_on_environment_id"

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "audited_changes"
    t.integer  "version",         :default => 0
    t.datetime "created_at"
    t.integer  "associated_id"
    t.string   "associated_type"
    t.string   "comment"
    t.string   "remote_address"
  end

  add_index "audits", ["associated_id", "associated_type"], :name => "associated_index"
  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"

  create_table "automation_queue_data", :force => true do |t|
    t.integer  "attempts",   :default => 0
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "failed_at"
    t.integer  "step_id"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "bladelogic_roles", :force => true do |t|
    t.integer  "bladelogic_user_id", :null => false
    t.string   "name",               :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bladelogic_roles", ["bladelogic_user_id"], :name => "index_bladelogic_roles_on_bladelogic_user_id"

  create_table "bladelogic_script_arguments", :force => true do |t|
    t.integer  "script_id"
    t.string   "argument"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_private"
    t.text     "choices"
  end

  add_index "bladelogic_script_arguments", ["script_id"], :name => "index_bladelogic_script_arguments_on_script_id"

  create_table "bladelogic_scripts", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "authentication"
    t.string   "script_class"
    t.string   "script_type"
    t.integer  "tag_id"
    t.integer  "integration_id"
    t.integer  "template_script_id"
    t.string   "template_script_type"
  end

  add_index "bladelogic_scripts", ["integration_id"], :name => "index_bladelogic_scripts_on_integration_id"
  add_index "bladelogic_scripts", ["tag_id"], :name => "index_bladelogic_scripts_on_tag_id"
  add_index "bladelogic_scripts", ["template_script_id"], :name => "index_bladelogic_scripts_on_template_script_id"

  create_table "bladelogic_users", :force => true do |t|
    t.string   "username",             :null => false
    t.integer  "streamdeploy_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "default_role"
  end

  add_index "bladelogic_users", ["streamdeploy_user_id"], :name => "index_bladelogic_users_on_streamdeploy_user_id"

  create_table "build_contents", :force => true do |t|
    t.integer  "query_id"
    t.integer  "plan_id"
    t.string   "object_i_d"
    t.string   "message"
    t.string   "status"
    t.string   "project"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "build_contents", ["plan_id"], :name => "index_build_contents_on_plan_id"
  add_index "build_contents", ["query_id"], :name => "index_build_contents_on_query_id"

  create_table "business_processes", :force => true do |t|
    t.string   "name",           :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "label_color"
    t.string   "archive_number"
    t.datetime "archived_at"
  end

  add_index "business_processes", ["archive_number"], :name => "index_business_processes_on_archive_number"
  add_index "business_processes", ["archived_at"], :name => "index_business_processes_on_archived_at"

  create_table "calendar_reports", :force => true do |t|
    t.string   "team_name"
    t.text     "report_url"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "calendar_reports", ["user_id"], :name => "index_calendar_reports_on_user_id"

  create_table "capistrano_script_arguments", :force => true do |t|
    t.integer  "script_id"
    t.string   "argument"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_private"
    t.text     "choices"
  end

  add_index "capistrano_script_arguments", ["script_id"], :name => "index_capistrano_script_arguments_on_script_id"

  create_table "capistrano_scripts", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "script_class"
    t.string   "script_type"
    t.integer  "tag_id"
    t.integer  "integration_id"
    t.integer  "template_script_id"
    t.string   "template_script_type"
  end

  add_index "capistrano_scripts", ["integration_id"], :name => "index_capistrano_scripts_on_integration_id"
  add_index "capistrano_scripts", ["tag_id"], :name => "index_capistrano_scripts_on_tag_id"
  add_index "capistrano_scripts", ["template_script_id"], :name => "index_capistrano_scripts_on_template_script_id"

  create_table "categories", :force => true do |t|
    t.string   "categorized_type"
    t.string   "name"
    t.string   "associated_events"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "archive_number"
    t.datetime "archived_at"
  end

  add_index "categories", ["archive_number"], :name => "index_categories_on_archive_number"
  add_index "categories", ["archived_at"], :name => "index_categories_on_archived_at"

  create_table "change_requests", :force => true do |t|
    t.integer  "project_server_id"
    t.integer  "plan_id"
    t.integer  "tab_id"
    t.text     "short_description"
    t.datetime "created_at",                                               :null => false
    t.datetime "updated_at",                                               :null => false
    t.string   "category"
    t.string   "sys_id"
    t.string   "cg_no"
    t.string   "start_date"
    t.string   "end_date"
    t.string   "planned_start_date"
    t.string   "planned_end_date"
    t.string   "approval"
    t.text     "description"
    t.boolean  "show_in_step",                          :default => false
    t.string   "u_application_name"
    t.string   "u_stage"
    t.string   "cr_state"
    t.string   "u_version_tag"
    t.integer  "query_id"
    t.string   "u_pmo_project_id"
    t.string   "u_cc_environment"
    t.string   "assignment_group"
    t.string   "risk"
    t.text     "change_plan"
    t.text     "backout_plan"
    t.text     "test_plan"
    t.string   "u_config_items_list",   :limit => 2000
    t.boolean  "saved_remotely",                        :default => true
    t.boolean  "deleted_remotely",                      :default => false
    t.string   "u_code_synch_required"
    t.boolean  "u_service_affecting",                   :default => true
    t.text     "u_release_notes"
    t.string   "cr_type"
    t.string   "u_streamstep_link"
  end

  add_index "change_requests", ["plan_id"], :name => "index_change_requests_on_plan_id"
  add_index "change_requests", ["project_server_id"], :name => "index_change_requests_on_project_server_id"
  add_index "change_requests", ["query_id"], :name => "index_change_requests_on_query_id"

  create_table "component_properties", :force => true do |t|
    t.integer "component_id"
    t.integer "property_id"
    t.integer "position"
  end

  add_index "component_properties", ["component_id"], :name => "index_component_properties_on_component_id"
  add_index "component_properties", ["property_id"], :name => "index_component_properties_on_property_id"

  create_table "component_templates", :force => true do |t|
    t.string   "name"
    t.string   "version"
    t.integer  "application_component_id"
    t.integer  "app_id"
    t.boolean  "active",                   :default => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.text     "description"
  end

  add_index "component_templates", ["app_id"], :name => "index_component_templates_on_app_id"
  add_index "component_templates", ["application_component_id"], :name => "index_component_templates_on_application_component_id"

  create_table "components", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",     :default => true
  end

  create_table "constraints", :force => true do |t|
    t.integer  "constrainable_id"
    t.string   "constrainable_type"
    t.integer  "governable_id"
    t.string   "governable_type"
    t.boolean  "active",             :default => true
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
  end

  add_index "constraints", ["active"], :name => "I_CONSTRAINT_ACTIVE"
  add_index "constraints", ["constrainable_id", "governable_id"], :name => "I_CONSTRAINT_CONST_GOV", :unique => true
  add_index "constraints", ["constrainable_id"], :name => "I_CONSTRAINT_CONST_ID"
  add_index "constraints", ["constrainable_type"], :name => "I_CONSTRAINT_CONST_TYPE"
  add_index "constraints", ["governable_id"], :name => "I_CONSTRAINT_GOV_ID"
  add_index "constraints", ["governable_type"], :name => "I_CONSTRAINT_GOV_TYPE"

  create_table "default_tabs", :force => true do |t|
    t.integer  "user_id"
    t.string   "tab_name",   :default => "Request"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "default_tabs", ["user_id"], :name => "index_default_tabs_on_user_id"

  create_table "deployment_window_events", :force => true do |t|
    t.integer  "occurrence_id"
    t.integer  "environment_id"
    t.string   "state"
    t.datetime "start_at"
    t.datetime "finish_at"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.integer  "cached_duration"
    t.text     "reason"
    t.string   "name"
    t.text     "environment_names"
    t.string   "behavior"
    t.integer  "requests_count",    :default => 0
  end

  add_index "deployment_window_events", ["environment_id"], :name => "DW_EVENT_ENV_ID"
  add_index "deployment_window_events", ["finish_at"], :name => "i_dw_event_finish_at"
  add_index "deployment_window_events", ["occurrence_id"], :name => "index_deployment_window_events_on_occurrence_id"
  add_index "deployment_window_events", ["start_at"], :name => "i_dw_event_start_at"

  create_table "deployment_window_occurrences", :force => true do |t|
    t.integer  "series_id"
    t.integer  "position"
    t.string   "state"
    t.datetime "start_at"
    t.datetime "finish_at"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.text     "environment_names"
  end

  add_index "deployment_window_occurrences", ["series_id"], :name => "DW_OCCUR_SERIES_ID"

  create_table "deployment_window_series", :force => true do |t|
    t.string   "name"
    t.string   "behavior"
    t.datetime "start_at"
    t.datetime "finish_at"
    t.boolean  "recurrent",             :default => false, :null => false
    t.text     "schedule"
    t.integer  "duration_in_days"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.string   "archive_number"
    t.boolean  "occurrences_ready",     :default => true,  :null => false
    t.datetime "archived_at"
    t.text     "environment_names"
    t.integer  "requests_count",        :default => 0
    t.string   "frequency_name"
    t.string   "frequency_description"
    t.string   "aasm_state"
    t.integer  "created_by"
  end

  add_index "deployment_window_series", ["frequency_name"], :name => "DW_SERIES_FREQUENCY"

  create_table "development_teams", :force => true do |t|
    t.integer  "app_id"
    t.integer  "team_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "development_teams", ["app_id"], :name => "index_development_teams_on_app_id"
  add_index "development_teams", ["team_id"], :name => "index_development_teams_on_team_id"

  create_table "email_recipients", :force => true do |t|
    t.integer  "request_id"
    t.integer  "recipient_id"
    t.string   "recipient_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_recipients", ["recipient_id", "recipient_type"], :name => "index_email_recipients_on_recipient_id_and_recipient_type"
  add_index "email_recipients", ["recipient_id"], :name => "index_email_recipients_on_recipient_id"
  add_index "email_recipients", ["request_id"], :name => "index_email_recipients_on_request_id"

  create_table "environment_roles", :force => true do |t|
    t.integer  "user_id"
    t.integer  "environment_id"
    t.boolean  "visible",        :default => false
    t.string   "role"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "environment_roles", ["environment_id"], :name => "index_environment_roles_on_environment_id"
  add_index "environment_roles", ["user_id"], :name => "index_environment_roles_on_user_id"

  create_table "environment_servers", :force => true do |t|
    t.integer  "environment_id"
    t.integer  "server_id"
    t.boolean  "default_server",   :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "server_aspect_id"
  end

  add_index "environment_servers", ["environment_id"], :name => "index_environment_servers_on_environment_id"
  add_index "environment_servers", ["server_aspect_id"], :name => "index_environment_servers_on_server_aspect_id"
  add_index "environment_servers", ["server_id"], :name => "index_environment_servers_on_server_id"

  create_table "environment_types", :force => true do |t|
    t.string   "name",                                  :null => false
    t.string   "description"
    t.integer  "position",       :default => 0,         :null => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.string   "archive_number"
    t.datetime "archived_at"
    t.boolean  "strict",         :default => false,     :null => false
    t.string   "label_color",    :default => "#D3D3D3", :null => false
  end

  add_index "environment_types", ["archive_number"], :name => "I_ENV_TYP_ARCH_NUM"
  add_index "environment_types", ["archived_at"], :name => "I_ENV_TYP_ARCH_AT"
  add_index "environment_types", ["name"], :name => "I_ENV_TYP_NAM", :unique => true
  add_index "environment_types", ["position"], :name => "I_ENV_TYP_POS"
  add_index "environment_types", ["strict"], :name => "I_ENV_TYPES_STRICT"

  create_table "environments", :force => true do |t|
    t.string   "name",                                          :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",                  :default => true,     :null => false
    t.integer  "default_server_group_id"
    t.boolean  "default",                 :default => false,    :null => false
    t.integer  "environment_type_id"
    t.string   "deployment_policy",       :default => "opened", :null => false
  end

  add_index "environments", ["default_server_group_id"], :name => "index_environments_on_default_server_group_id"
  add_index "environments", ["environment_type_id"], :name => "I_ENV_ENV_TYP_ID"

  create_table "environments_server_groups", :id => false, :force => true do |t|
    t.integer "environment_id"
    t.integer "server_group_id"
  end

  add_index "environments_server_groups", ["environment_id"], :name => "index_environments_server_groups_on_environment_id"
  add_index "environments_server_groups", ["server_group_id"], :name => "index_environments_server_groups_on_server_group_id"

  create_table "extended_attributes", :force => true do |t|
    t.string   "name"
    t.string   "value_text"
    t.integer  "value_holder_id"
    t.string   "value_holder_type"
    t.boolean  "active"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "extended_attributes", ["value_holder_id", "value_holder_type"], :name => "i_ex_at_va_ho_id_va_ho_ty"

  create_table "global_settings", :force => true do |t|
    t.string   "default_logo"
    t.string   "company_name"
    t.integer  "base_request_number"
    t.boolean  "bladelogic_enabled"
    t.string   "bladelogic_ip_address"
    t.string   "bladelogic_username"
    t.string   "bladelogic_password"
    t.string   "bladelogic_rolename"
    t.string   "bladelogic_profile"
    t.boolean  "capistrano_enabled"
    t.boolean  "hudson_enabled"
    t.string   "session_key"
    t.string   "timezone"
    t.boolean  "one_click_completion"
    t.integer  "authentication_mode"
    t.boolean  "multi_app_requests"
    t.string   "default_date_format"
    t.boolean  "forgot_password"
    t.string   "ldap_host"
    t.string   "ldap_port"
    t.string   "ldap_component"
    t.string   "cas_server"
    t.string   "base_url"
    t.string   "calendar_preferences",      :limit => 1000
    t.datetime "created_at",                                                   :null => false
    t.datetime "updated_at",                                                   :null => false
    t.boolean  "limit_versions"
    t.boolean  "automation_enabled",                        :default => false
    t.boolean  "commit_on_completion",                      :default => true
    t.string   "ldap_bind_user"
    t.string   "ldap_bind_password"
    t.string   "ldap_bind_base"
    t.string   "ldap_account_attribute"
    t.integer  "ldap_auth_type",                            :default => 0,     :null => false
    t.string   "ldap_first_name_attribute"
    t.string   "ldap_last_name_attribute"
    t.string   "ldap_mail_attribute"
    t.integer  "session_timeout"
  end

  create_table "group_management", :id => false, :force => true do |t|
    t.integer "manager_id"
    t.integer "group_id"
  end

  add_index "group_management", ["group_id"], :name => "index_group_management_on_group_id"
  add_index "group_management", ["manager_id"], :name => "index_group_management_on_manager_id"

  create_table "group_roles", :force => true do |t|
    t.integer  "group_id"
    t.integer  "role_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.integer  "position"
    t.boolean  "active",     :default => true
    t.boolean  "root",       :default => false
  end

  create_table "icsags", :id => false, :force => true do |t|
    t.integer "installed_component_id"
    t.integer "server_aspect_group_id"
  end

  add_index "icsags", ["installed_component_id"], :name => "index_icsags_on_installed_component_id"
  add_index "icsags", ["server_aspect_group_id"], :name => "index_icsags_on_server_aspect_group_id"

  create_table "icsas", :id => false, :force => true do |t|
    t.integer "installed_component_id"
    t.integer "server_aspect_id"
  end

  add_index "icsas", ["installed_component_id"], :name => "index_icsas_on_installed_component_id"
  add_index "icsas", ["server_aspect_id"], :name => "index_icsas_on_server_aspect_id"

  create_table "installed_components", :force => true do |t|
    t.integer  "application_component_id"
    t.integer  "application_environment_id"
    t.string   "location"
    t.string   "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "default_server_group_id"
    t.integer  "reference_id"
  end

  add_index "installed_components", ["application_component_id", "application_environment_id"], :name => "ic_ac_ae_id"
  add_index "installed_components", ["application_component_id"], :name => "index_installed_components_on_application_component_id"
  add_index "installed_components", ["application_environment_id"], :name => "index_installed_components_on_application_environment_id"
  add_index "installed_components", ["default_server_group_id"], :name => "index_installed_components_on_default_server_group_id"
  add_index "installed_components", ["reference_id"], :name => "index_installed_components_on_reference_id"

  create_table "installed_components_servers", :id => false, :force => true do |t|
    t.integer "installed_component_id", :null => false
    t.integer "server_id",              :null => false
  end

  add_index "installed_components_servers", ["installed_component_id"], :name => "index_installed_components_servers_on_installed_component_id"
  add_index "installed_components_servers", ["server_id"], :name => "index_installed_components_servers_on_server_id"

  create_table "instance_references", :force => true do |t|
    t.string   "name",                                    :null => false
    t.string   "uri",                                     :null => false
    t.integer  "package_instance_id",                     :null => false
    t.integer  "server_id"
    t.integer  "reference_id",                            :null => false
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.string   "resource_method",     :default => "File"
  end

  create_table "integration_csv_columns", :force => true do |t|
    t.integer  "integration_csv_id"
    t.string   "name"
    t.boolean  "primary",            :default => false
    t.boolean  "active",             :default => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  add_index "integration_csv_columns", ["integration_csv_id"], :name => "index_integration_csv_columns_on_integration_csv_id"

  create_table "integration_csv_data", :force => true do |t|
    t.integer  "integration_csv_column_id"
    t.text     "value"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "integration_csv_data", ["integration_csv_column_id"], :name => "index_integration_csv_data_on_integration_csv_column_id"

  create_table "integration_csvs", :force => true do |t|
    t.string   "name"
    t.integer  "project_server_id"
    t.integer  "plan_id"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.integer  "user_id"
    t.integer  "tab_id",            :default => 1
  end

  add_index "integration_csvs", ["plan_id"], :name => "index_integration_csvs_on_plan_id"
  add_index "integration_csvs", ["project_server_id"], :name => "index_integration_csvs_on_project_server_id"
  add_index "integration_csvs", ["user_id"], :name => "index_integration_csvs_on_user_id"

  create_table "integration_projects", :force => true do |t|
    t.string   "name"
    t.integer  "project_server_id"
    t.boolean  "active",            :default => true
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.integer  "parent_id"
    t.string   "object_i_d"
  end

  add_index "integration_projects", ["project_server_id"], :name => "index_integration_projects_on_project_server_id"

  create_table "integration_releases", :force => true do |t|
    t.string   "name"
    t.integer  "integration_project_id"
    t.boolean  "active",                 :default => true
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
  end

  add_index "integration_releases", ["integration_project_id"], :name => "index_integration_releases_on_integration_project_id"

  create_table "integrations", :force => true do |t|
    t.string   "name"
    t.string   "integration_type"
    t.string   "dns"
    t.string   "server_url"
    t.integer  "port"
    t.string   "username"
    t.string   "password"
    t.text     "connection_params"
    t.text     "description"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "job_runs", :force => true do |t|
    t.string   "job_type"
    t.string   "status"
    t.integer  "run_key"
    t.integer  "user_id"
    t.integer  "process_id"
    t.integer  "automation_id"
    t.integer  "step_id"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string   "results_path"
    t.text     "stdout"
    t.text     "stderr"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "job_runs", ["run_key"], :name => "index_job_runs_on_run_key"
  add_index "job_runs", ["step_id"], :name => "index_job_runs_on_step_id"

  create_table "linked_items", :force => true do |t|
    t.string   "name"
    t.integer  "source_holder_id",   :null => false
    t.string   "source_holder_type", :null => false
    t.integer  "target_holder_id",   :null => false
    t.string   "target_holder_type", :null => false
    t.integer  "rule_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  add_index "linked_items", ["source_holder_id", "source_holder_type"], :name => "index_linked_items_on_source_holder_id_and_source_holder_type"
  add_index "linked_items", ["source_holder_id"], :name => "index_linked_items_on_source_holder_id"
  add_index "linked_items", ["target_holder_id", "target_holder_type"], :name => "index_linked_items_on_target_holder_id_and_target_holder_type"
  add_index "linked_items", ["target_holder_id"], :name => "index_linked_items_on_target_holder_id"

  create_table "list_items", :force => true do |t|
    t.integer  "list_id"
    t.string   "value_text"
    t.integer  "value_num"
    t.integer  "last_modified_by_id"
    t.boolean  "is_active",           :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "archive_number"
    t.datetime "archived_at"
  end

  add_index "list_items", ["archive_number"], :name => "index_list_items_on_archive_number"
  add_index "list_items", ["archived_at"], :name => "index_list_items_on_archived_at"
  add_index "list_items", ["list_id"], :name => "index_list_items_on_list_id"

  create_table "lists", :force => true do |t|
    t.string   "name"
    t.integer  "created_by_id"
    t.boolean  "is_text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "archive_number"
    t.datetime "archived_at"
    t.boolean  "is_hash",        :default => false, :null => false
  end

  add_index "lists", ["archive_number"], :name => "index_lists_on_archive_number"
  add_index "lists", ["archived_at"], :name => "index_lists_on_archived_at"
  add_index "lists", ["created_by_id"], :name => "index_lists_on_created_by_id"

  create_table "messages", :force => true do |t|
    t.integer  "sender_id",  :null => false
    t.integer  "request_id", :null => false
    t.string   "subject"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "messages", ["request_id"], :name => "index_messages_on_request_id"
  add_index "messages", ["sender_id"], :name => "index_messages_on_sender_id"

  create_table "notes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "object_id"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "holder_type"
    t.string   "holder_type_id"
    t.string   "object_type"
  end

  add_index "notes", ["object_id", "object_type"], :name => "index_notes_on_object_id_and_object_type"
  add_index "notes", ["object_id"], :name => "notes_by_step"
  add_index "notes", ["user_id"], :name => "index_notes_on_user_id"

  create_table "notification_templates", :force => true do |t|
    t.string   "title",                                 :null => false
    t.string   "format",      :default => "email_text", :null => false
    t.string   "event",                                 :null => false
    t.text     "description"
    t.text     "body"
    t.text     "template"
    t.boolean  "active",      :default => false,        :null => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.string   "subject"
  end

  add_index "notification_templates", ["event"], :name => "i_nt_event"
  add_index "notification_templates", ["format"], :name => "i_nt_method"
  add_index "notification_templates", ["title"], :name => "i_nt_title"

  create_table "p_stages_request_templates", :force => true do |t|
    t.integer "plan_stage_id"
    t.integer "request_template_id"
  end

  add_index "p_stages_request_templates", ["plan_stage_id"], :name => "index_lc_stages_request_templates_on_plan_stage_id"
  add_index "p_stages_request_templates", ["request_template_id"], :name => "index_lc_stages_request_templates_on_request_template_id"

  create_table "package_contents", :force => true do |t|
    t.string   "name"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "abbreviation"
    t.string   "archive_number"
    t.datetime "archived_at"
  end

  add_index "package_contents", ["archive_number"], :name => "index_package_contents_on_archive_number"
  add_index "package_contents", ["archived_at"], :name => "index_package_contents_on_archived_at"

  create_table "package_instances", :force => true do |t|
    t.string   "name"
    t.boolean  "active"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "package_id"
  end

  create_table "package_properties", :force => true do |t|
    t.integer "package_id"
    t.integer "property_id"
    t.integer "position"
  end

  create_table "package_references", :force => true do |t|
    t.string   "name",                                :null => false
    t.string   "uri",                                 :null => false
    t.integer  "package_id"
    t.integer  "server_id"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.string   "resource_method", :default => "File"
  end

  create_table "package_template_components", :force => true do |t|
    t.integer  "package_template_item_id"
    t.integer  "application_component_id"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "package_template_components", ["application_component_id"], :name => "index_package_template_components_on_application_component_id"
  add_index "package_template_components", ["package_template_item_id"], :name => "index_package_template_components_on_package_template_item_id"

  create_table "package_template_items", :force => true do |t|
    t.integer  "package_template_id"
    t.integer  "position"
    t.integer  "item_type"
    t.string   "name"
    t.string   "description"
    t.integer  "component_template_id"
    t.text     "properties"
    t.text     "commands"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  add_index "package_template_items", ["component_template_id"], :name => "index_package_template_items_on_component_template_id"
  add_index "package_template_items", ["package_template_id"], :name => "index_package_template_items_on_package_template_id"

  create_table "package_templates", :force => true do |t|
    t.string   "name"
    t.string   "version"
    t.integer  "app_id"
    t.boolean  "active",     :default => true
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "package_templates", ["app_id"], :name => "index_package_templates_on_app_id"

  create_table "packages", :force => true do |t|
    t.string   "name"
    t.string   "instance_name_format"
    t.integer  "next_instance_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",               :default => true
  end

  create_table "permissions", :force => true do |t|
    t.string   "name",                           :null => false
    t.string   "action"
    t.string   "subject"
    t.boolean  "is_instance", :default => false, :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  create_table "phases", :force => true do |t|
    t.string   "name"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "archive_number"
    t.datetime "archived_at"
  end

  add_index "phases", ["archive_number"], :name => "index_phases_on_archive_number"
  add_index "phases", ["archived_at"], :name => "index_phases_on_archived_at"

  create_table "plan_env_app_dates", :force => true do |t|
    t.integer  "plan_id",          :null => false
    t.integer  "plan_template_id", :null => false
    t.integer  "environment_id",   :null => false
    t.integer  "app_id",           :null => false
    t.date     "planned_start"
    t.date     "planned_complete"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at"
    t.integer  "created_by",       :null => false
    t.integer  "updated_by"
  end

  add_index "plan_env_app_dates", ["app_id"], :name => "index_plan_env_app_dates_on_app_id"
  add_index "plan_env_app_dates", ["environment_id"], :name => "index_plan_env_app_dates_on_environment_id"
  add_index "plan_env_app_dates", ["plan_id"], :name => "index_plan_env_app_dates_on_plan_id"

  create_table "plan_members", :force => true do |t|
    t.integer  "plan_stage_id"
    t.integer  "plan_stage_status_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "plan_id",                                          :null => false
    t.integer  "position"
    t.integer  "run_id"
    t.boolean  "parallel",                      :default => false, :null => false
    t.boolean  "different_level_from_previous", :default => true,  :null => false
  end

  add_index "plan_members", ["different_level_from_previous"], :name => "i_plan_member_on_dlfp"
  add_index "plan_members", ["parallel"], :name => "index_lifecycle_members_on_parallel"
  add_index "plan_members", ["plan_id"], :name => "index_lifecycle_members_on_plan_id"
  add_index "plan_members", ["plan_stage_id", "position"], :name => "index_lifecycle_members_on_plan_stage_id_and_position"
  add_index "plan_members", ["plan_stage_id"], :name => "index_lifecycle_members_on_plan_stage_id"
  add_index "plan_members", ["plan_stage_status_id"], :name => "index_lifecycle_members_on_plan_stage_status_id"
  add_index "plan_members", ["run_id"], :name => "index_plan_members_on_run_id"

  create_table "plan_routes", :force => true do |t|
    t.integer  "plan_id",    :null => false
    t.integer  "route_id",   :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "plan_routes", ["plan_id"], :name => "I_PLAN_ROUTE_PLAN_ID"
  add_index "plan_routes", ["route_id"], :name => "I_PLAN_ROUTE_ROUTE_ID"

  create_table "plan_stage_dates", :force => true do |t|
    t.integer  "plan_id",       :null => false
    t.integer  "plan_stage_id", :null => false
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "plan_stage_dates", ["end_date"], :name => "i_plan_stage_dates_end_date"
  add_index "plan_stage_dates", ["plan_id"], :name => "index_lifecycle_stage_dates_on_plan_id"
  add_index "plan_stage_dates", ["plan_stage_id"], :name => "index_lifecycle_stage_dates_on_plan_stage_id"
  add_index "plan_stage_dates", ["start_date", "end_date"], :name => "i_plan_stage_dates_start_end"

  create_table "plan_stage_instances", :force => true do |t|
    t.integer  "plan_id",                                 :null => false
    t.integer  "plan_stage_id",                           :null => false
    t.string   "aasm_state",     :default => "compliant", :null => false
    t.datetime "archived_at"
    t.string   "archive_number"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
  end

  add_index "plan_stage_instances", ["aasm_state"], :name => "I_PSI_aasm_state"
  add_index "plan_stage_instances", ["archive_number"], :name => "I_PSI_archive_number"
  add_index "plan_stage_instances", ["archived_at"], :name => "I_PSI_archived_at"
  add_index "plan_stage_instances", ["plan_id"], :name => "I_PSI_plan_id"
  add_index "plan_stage_instances", ["plan_stage_id"], :name => "I_PSI_plan_stage_id"

  create_table "plan_stage_statuses", :force => true do |t|
    t.string   "name",          :null => false
    t.integer  "plan_stage_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
  end

  add_index "plan_stage_statuses", ["name"], :name => "i_plan_pss_name"
  add_index "plan_stage_statuses", ["plan_stage_id", "position"], :name => "index_lifecycle_stage_statuses_on_plan_stage_id_and_position"
  add_index "plan_stage_statuses", ["plan_stage_id"], :name => "index_plan_stage_statuses_on_plan_stage_id"

  create_table "plan_stages", :force => true do |t|
    t.string   "name",                                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "plan_template_id",                       :null => false
    t.integer  "position"
    t.boolean  "auto_start",          :default => false, :null => false
    t.boolean  "requestor_access",    :default => true
    t.integer  "environment_type_id"
    t.boolean  "required",            :default => false, :null => false
  end

  add_index "plan_stages", ["auto_start"], :name => "i_plan_stages_auto_start"
  add_index "plan_stages", ["environment_type_id"], :name => "I_PLA_STA_ENV_TYP_ID"
  add_index "plan_stages", ["name"], :name => "i_plan_stages_name"
  add_index "plan_stages", ["plan_template_id"], :name => "index_lifecycle_stages_on_plan_template_id"
  add_index "plan_stages", ["position"], :name => "i_plan_stages_position"
  add_index "plan_stages", ["required"], :name => "I_PS_REQUIRED"

  create_table "plan_teams", :force => true do |t|
    t.integer  "plan_id"
    t.integer  "team_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "plan_teams", ["plan_id"], :name => "index_lifecycle_teams_on_plan_id"
  add_index "plan_teams", ["team_id"], :name => "index_plan_teams_on_team_id"

  create_table "plan_templates", :force => true do |t|
    t.string   "name",                              :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "template_type",                     :null => false
    t.boolean  "is_automatic",   :default => false
    t.string   "archive_number"
    t.datetime "archived_at"
    t.string   "aasm_state"
    t.integer  "created_by"
  end

  add_index "plan_templates", ["archive_number"], :name => "index_lifecycle_templates_on_archive_number"
  add_index "plan_templates", ["archived_at"], :name => "index_lifecycle_templates_on_archived_at"
  add_index "plan_templates", ["is_automatic"], :name => "i_pt_is_auto"
  add_index "plan_templates", ["name"], :name => "i_pt_name", :unique => true
  add_index "plan_templates", ["template_type"], :name => "i_pt_template_type"

  create_table "plans", :force => true do |t|
    t.integer  "plan_template_id",                          :null => false
    t.string   "name",                                      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "release_manager_id"
    t.date     "release_date"
    t.integer  "release_id"
    t.string   "aasm_state",         :default => "created"
    t.text     "description"
    t.string   "foreign_id"
    t.integer  "project_server_id"
  end

  add_index "plans", ["aasm_state"], :name => "index_lifecycles_on_aasm_state"
  add_index "plans", ["name"], :name => "index_lifecycles_on_name"
  add_index "plans", ["plan_template_id"], :name => "index_lifecycles_on_lifecycle_template_id"
  add_index "plans", ["project_server_id"], :name => "index_plans_on_project_server_id"
  add_index "plans", ["release_id"], :name => "index_lifecycles_on_release_id"
  add_index "plans", ["release_manager_id"], :name => "index_lifecycles_on_release_manager_id"

  create_table "preferences", :force => true do |t|
    t.integer  "user_id"
    t.string   "text"
    t.integer  "position"
    t.boolean  "active",          :default => true
    t.string   "preference_type", :default => "Request"
    t.string   "string",          :default => "Request"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "preferences", ["preference_type"], :name => "index_preferences_on_preference_type"
  add_index "preferences", ["text"], :name => "index_preferences_on_text"
  add_index "preferences", ["user_id", "active"], :name => "index_preferences_on_user_id_and_active"
  add_index "preferences", ["user_id", "position"], :name => "index_preferences_on_user_id_and_position"
  add_index "preferences", ["user_id"], :name => "index_preferences_on_user_id"

  create_table "procedures", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "archive_number"
    t.datetime "archived_at"
    t.string   "aasm_state"
    t.integer  "created_by"
  end

  add_index "procedures", ["archive_number"], :name => "index_procedures_on_archive_number"
  add_index "procedures", ["archived_at"], :name => "index_procedures_on_archived_at"

  create_table "project_servers", :force => true do |t|
    t.integer  "server_name_id"
    t.string   "name"
    t.string   "ip"
    t.string   "server_url"
    t.integer  "port"
    t.string   "username"
    t.string   "password"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.boolean  "is_active",                 :default => true
    t.text     "details"
    t.boolean  "workspace_data_available",  :default => false
    t.datetime "data_loading_started_at"
    t.datetime "data_loading_completed_at"
  end

  create_table "properties", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",                        :default => true, :null => false
    t.string   "default_value", :limit => 4000
    t.boolean  "is_private"
  end

  create_table "properties_servers", :id => false, :force => true do |t|
    t.integer "property_id", :null => false
    t.integer "server_id",   :null => false
  end

  add_index "properties_servers", ["property_id"], :name => "index_properties_servers_on_property_id"
  add_index "properties_servers", ["server_id"], :name => "index_properties_servers_on_server_id"

  create_table "property_values", :force => true do |t|
    t.string   "value",             :limit => 4000
    t.integer  "value_holder_id"
    t.integer  "property_id"
    t.datetime "created_at"
    t.datetime "deleted_at"
    t.string   "value_holder_type",                                    :null => false
    t.boolean  "locked",                            :default => false, :null => false
  end

  add_index "property_values", ["property_id", "value_holder_id"], :name => "pvs_pid_icid"
  add_index "property_values", ["property_id"], :name => "index_property_values_on_property_id"
  add_index "property_values", ["value_holder_id", "value_holder_type"], :name => "index_property_values_on_value_holder_id_and_value_holder_type"
  add_index "property_values", ["value_holder_id"], :name => "index_property_values_on_value_holder_id"

  create_table "property_work_tasks", :force => true do |t|
    t.integer  "property_id"
    t.integer  "work_task_id"
    t.boolean  "entry_during_step_execution", :default => false, :null => false
    t.boolean  "entry_during_step_creation",  :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "property_work_tasks", ["property_id"], :name => "index_property_tasks_on_property_id"
  add_index "property_work_tasks", ["work_task_id"], :name => "index_property_tasks_on_work_task_id"

  create_table "queries", :force => true do |t|
    t.integer  "project_server_id"
    t.integer  "plan_id"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.string   "name"
    t.string   "project"
    t.string   "iteration"
    t.string   "release"
    t.string   "rally_project_id"
    t.integer  "rally_iteration_id", :limit => 8
    t.integer  "rally_release_id",   :limit => 8
    t.datetime "last_run_at"
    t.integer  "last_run_by"
    t.string   "rally_data_type"
    t.string   "artifacts"
    t.integer  "tab_id",                          :default => 1
    t.boolean  "running",                         :default => false
    t.text     "query"
    t.text     "humanized_query"
    t.integer  "script_id"
  end

  add_index "queries", ["last_run_by"], :name => "index_queries_on_last_run_by"
  add_index "queries", ["plan_id"], :name => "index_queries_on_plan_id"
  add_index "queries", ["project_server_id"], :name => "index_queries_on_project_server_id"
  add_index "queries", ["script_id"], :name => "index_queries_on_script_id"

  create_table "query_details", :force => true do |t|
    t.integer  "query_id"
    t.string   "query_element"
    t.string   "query_criteria"
    t.string   "query_term"
    t.string   "conjuction"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "query_details", ["query_id"], :name => "index_query_details_on_query_id"

  create_table "recent_activities", :force => true do |t|
    t.string   "verb",                 :null => false
    t.integer  "actor_id"
    t.string   "actor_type"
    t.integer  "object_id"
    t.string   "object_type"
    t.integer  "indirect_object_id"
    t.string   "indirect_object_type"
    t.string   "context"
    t.datetime "timestamp",            :null => false
  end

  add_index "recent_activities", ["actor_id", "actor_type"], :name => "index_recent_activities_on_actor_id_and_actor_type"
  add_index "recent_activities", ["actor_id"], :name => "index_recent_activities_on_actor_id"
  add_index "recent_activities", ["indirect_object_id", "indirect_object_type"], :name => "recent_act_indobjid_indobjtype"
  add_index "recent_activities", ["indirect_object_id"], :name => "index_recent_activities_on_indirect_object_id"
  add_index "recent_activities", ["object_id", "object_type"], :name => "index_recent_activities_on_object_id_and_object_type"
  add_index "recent_activities", ["object_id"], :name => "index_recent_activities_on_object_id"

  create_table "recurrences", :force => true do |t|
    t.text     "start_date"
    t.text     "end_time"
    t.text     "rrules"
    t.text     "exrules"
    t.text     "rtimes"
    t.text     "extimes"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "release_content_items", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "plan_id"
    t.integer  "integration_project_id"
    t.integer  "integration_release_id"
    t.string   "schedule_state"
    t.boolean  "active",                 :default => true
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.integer  "tab_id",                 :default => 1
    t.boolean  "show_in_step",           :default => true
  end

  add_index "release_content_items", ["integration_project_id"], :name => "index_release_content_items_on_integration_project_id"
  add_index "release_content_items", ["integration_release_id"], :name => "index_release_content_items_on_integration_release_id"
  add_index "release_content_items", ["plan_id"], :name => "index_release_content_items_on_plan_id"

  create_table "release_contents", :force => true do |t|
    t.integer  "query_id"
    t.integer  "plan_id"
    t.string   "formatted_i_d"
    t.string   "name"
    t.string   "schedule_state"
    t.string   "owner"
    t.string   "project"
    t.string   "package"
    t.text     "description"
    t.datetime "creation_date"
    t.datetime "last_update_date"
    t.datetime "accepted_date"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.string   "iteration"
    t.string   "release"
    t.integer  "tab_id",           :default => 1
  end

  add_index "release_contents", ["plan_id"], :name => "index_release_contents_on_plan_id"
  add_index "release_contents", ["query_id"], :name => "index_release_contents_on_query_id"

  create_table "releases", :force => true do |t|
    t.string   "name",           :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.string   "archive_number"
    t.datetime "archived_at"
  end

  add_index "releases", ["archive_number"], :name => "index_releases_on_archive_number"
  add_index "releases", ["archived_at"], :name => "index_releases_on_archived_at"

  create_table "request_package_contents", :force => true do |t|
    t.integer  "request_id"
    t.integer  "package_content_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "request_package_contents", ["package_content_id"], :name => "index_request_package_contents_on_package_content_id"
  add_index "request_package_contents", ["request_id"], :name => "index_request_package_contents_on_request_id"

  create_table "request_templates", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "recur_time"
    t.integer  "team_id"
    t.integer  "parent_id"
    t.string   "archive_number"
    t.datetime "archived_at"
    t.string   "aasm_state"
    t.integer  "created_by"
  end

  add_index "request_templates", ["archive_number"], :name => "index_request_templates_on_archive_number"
  add_index "request_templates", ["archived_at"], :name => "index_request_templates_on_archived_at"
  add_index "request_templates", ["parent_id"], :name => "index_request_templates_on_parent_id"
  add_index "request_templates", ["team_id"], :name => "index_request_templates_on_team_id"

  create_table "requests", :force => true do |t|
    t.integer  "business_process_id"
    t.integer  "app_id"
    t.integer  "environment_id",                 :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "scheduled_at"
    t.datetime "target_completion_at"
    t.boolean  "notify_on_request_start",        :default => false, :null => false
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
    t.boolean  "notify_on_request_complete",     :default => false, :null => false
    t.boolean  "notify_on_step_complete",        :default => false, :null => false
    t.boolean  "notify_on_step_start",           :default => false, :null => false
    t.string   "additional_email_addresses"
    t.datetime "planned_at"
    t.datetime "deleted_at"
    t.boolean  "notify_on_request_hold",         :default => false, :null => false
    t.boolean  "notify_on_step_block",           :default => false, :null => false
    t.string   "name"
    t.text     "description"
    t.integer  "requestor_id"
    t.binary   "frozen_requestor"
    t.integer  "activity_id"
    t.boolean  "auto_start",                     :default => false, :null => false
    t.text     "wiki_url"
    t.integer  "plan_member_id"
    t.integer  "server_association_id"
    t.string   "server_association_type"
    t.integer  "owner_id"
    t.boolean  "rescheduled"
    t.boolean  "promotion",                      :default => false
    t.datetime "cancelled_at"
    t.boolean  "created_from_template",          :default => false
    t.boolean  "notify_on_step_problem"
    t.boolean  "notify_on_step_ready"
    t.boolean  "notify_on_request_cancel"
    t.boolean  "notify_on_request_planned",      :default => false, :null => false
    t.boolean  "notify_on_request_problem",      :default => false, :null => false
    t.boolean  "notify_on_request_resolved",     :default => false
    t.boolean  "notify_on_request_step_owners",  :default => false, :null => false
    t.boolean  "notify_on_step_step_owners",     :default => false, :null => false
    t.boolean  "notify_on_step_requestor_owner", :default => false, :null => false
    t.boolean  "notify_on_step_participiant",    :default => false, :null => false
    t.boolean  "notify_on_request_participiant", :default => false, :null => false
    t.boolean  "notify_group_only",              :default => true,  :null => false
    t.integer  "origin_request_template_id"
    t.integer  "estimate"
    t.integer  "parent_request_id"
    t.integer  "deployment_window_event_id"
    t.boolean  "notify_on_dw_fail",              :default => false, :null => false
    t.text     "automatically_start_errors"
  end

  add_index "requests", ["aasm_state"], :name => "index_requests_on_aasm_state"
  add_index "requests", ["activity_id"], :name => "index_requests_on_activity_id"
  add_index "requests", ["app_id"], :name => "apps_by_request"
  add_index "requests", ["business_process_id"], :name => "index_requests_on_business_process_id"
  add_index "requests", ["category_id"], :name => "index_requests_on_category_id"
  add_index "requests", ["deployment_coordinator_id"], :name => "index_requests_on_deployment_coordinator_id"
  add_index "requests", ["deployment_window_event_id"], :name => "REQUESTS_DWE_ID"
  add_index "requests", ["environment_id"], :name => "index_requests_on_environment_id"
  add_index "requests", ["origin_request_template_id"], :name => "index_requests_on_origin_request_template_id"
  add_index "requests", ["owner_id"], :name => "index_requests_on_owner_id"
  add_index "requests", ["plan_member_id"], :name => "index_requests_on_plan_member_id"
  add_index "requests", ["release_id"], :name => "index_requests_on_release_id"
  add_index "requests", ["request_template_id"], :name => "index_requests_on_request_template_id"
  add_index "requests", ["requestor_id"], :name => "index_requests_on_requestor_id"
  add_index "requests", ["server_association_id", "server_association_type"], :name => "req_svrassocid_svrassoctype"
  add_index "requests", ["server_association_id"], :name => "index_requests_on_server_association_id"

  create_table "resource_allocations", :force => true do |t|
    t.integer  "allocated_id",                    :null => false
    t.string   "allocated_type",                  :null => false
    t.integer  "allocation",     :default => 100, :null => false
    t.integer  "year",                            :null => false
    t.integer  "month",                           :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resource_allocations", ["allocated_id", "allocated_type"], :name => "index_resource_allocations_on_allocated_id_and_allocated_type"
  add_index "resource_allocations", ["allocated_id"], :name => "index_resource_allocations_on_allocated_id"

  create_table "role_permissions", :force => true do |t|
    t.integer  "role_id"
    t.integer  "permission_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.boolean  "active",      :default => true
  end

  create_table "route_gates", :force => true do |t|
    t.integer  "route_id",                                        :null => false
    t.integer  "environment_id",                                  :null => false
    t.string   "description"
    t.integer  "position",                      :default => 0,    :null => false
    t.boolean  "different_level_from_previous", :default => true, :null => false
    t.string   "archive_number"
    t.datetime "archived_at"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
  end

  add_index "route_gates", ["archive_number"], :name => "I_RG_ARCH_NUM"
  add_index "route_gates", ["archived_at"], :name => "I_RG_ARCH_AT"
  add_index "route_gates", ["different_level_from_previous"], :name => "I_RG_DLFPRV"
  add_index "route_gates", ["environment_id"], :name => "I_RG_ENVIRONMENT_ID"
  add_index "route_gates", ["position"], :name => "I_RG_POSITION"
  add_index "route_gates", ["route_id"], :name => "I_RG_ROUTE_ID"

  create_table "routes", :force => true do |t|
    t.string   "name",                               :null => false
    t.integer  "app_id",                             :null => false
    t.string   "description"
    t.string   "route_type",     :default => "open", :null => false
    t.string   "archive_number"
    t.datetime "archived_at"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "routes", ["app_id"], :name => "I_ROUTE_APP_ID"
  add_index "routes", ["archive_number"], :name => "I_ROUTE_ARCH_NUM"
  add_index "routes", ["archived_at"], :name => "I_ROUTE_ARCH_AT"
  add_index "routes", ["name"], :name => "I_ROUTE_NAME"
  add_index "routes", ["route_type"], :name => "I_ROUTE_TYPE"

  create_table "rules", :force => true do |t|
    t.string "name"
    t.string "value_context"
  end

  create_table "runs", :force => true do |t|
    t.string   "name"
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "duration"
    t.string   "description"
    t.integer  "requestor_id"
    t.integer  "owner_id"
    t.integer  "plan_id"
    t.integer  "plan_stage_id"
    t.string   "aasm_state",    :default => "created"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.boolean  "auto_promote",  :default => false,     :null => false
  end

  add_index "runs", ["auto_promote"], :name => "I_RUN_AUTO_PROMOTE"
  add_index "runs", ["end_at"], :name => "index_runs_on_end_at"
  add_index "runs", ["name"], :name => "index_runs_on_name"
  add_index "runs", ["owner_id"], :name => "index_runs_on_owner_id"
  add_index "runs", ["plan_id"], :name => "index_runs_on_plan_id"
  add_index "runs", ["plan_stage_id"], :name => "index_runs_on_plan_stage_id"
  add_index "runs", ["requestor_id"], :name => "index_runs_on_requestor_id"
  add_index "runs", ["start_at"], :name => "index_runs_on_start_at"

  create_table "runtime_phases", :force => true do |t|
    t.integer  "phase_id"
    t.string   "name"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "runtime_phases", ["phase_id"], :name => "index_runtime_phases_on_phase_id"

  create_table "sagsas", :id => false, :force => true do |t|
    t.integer "server_aspect_group_id"
    t.integer "server_aspect_id"
  end

  add_index "sagsas", ["server_aspect_group_id"], :name => "index_sagsas_on_server_aspect_group_id"
  add_index "sagsas", ["server_aspect_id"], :name => "index_sagsas_on_server_aspect_id"

  create_table "satpms", :force => true do |t|
    t.integer  "script_argument_id"
    t.string   "script_argument_type"
    t.integer  "property_id"
    t.integer  "value_holder_id",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "value_holder_type",    :null => false
  end

  add_index "satpms", ["property_id"], :name => "index_satpms_on_property_id"
  add_index "satpms", ["script_argument_id", "script_argument_type"], :name => "index_satpms_on_script_argument_id_and_script_argument_type"
  add_index "satpms", ["script_argument_id"], :name => "index_satpms_on_script_argument_id"
  add_index "satpms", ["value_holder_id", "value_holder_type"], :name => "index_satpms_on_value_holder_id_and_value_holder_type"
  add_index "satpms", ["value_holder_id"], :name => "index_satpms_on_value_holder_id"

  create_table "scheduled_jobs", :force => true do |t|
    t.integer  "resource_id",                            :null => false
    t.string   "resource_type",                          :null => false
    t.integer  "owner_id",                               :null => false
    t.string   "status",        :default => "Scheduled", :null => false
    t.datetime "planned_at",                             :null => false
    t.text     "log",                                    :null => false
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "scheduled_jobs", ["owner_id"], :name => "I_SCH_JOB_OWNER_ID"
  add_index "scheduled_jobs", ["planned_at"], :name => "I_SCH_JOB_PLAN_DT"
  add_index "scheduled_jobs", ["resource_id"], :name => "I_SCH_JOB_RES_ID"
  add_index "scheduled_jobs", ["resource_type"], :name => "I_SCH_JOB_RES_TYPE"
  add_index "scheduled_jobs", ["status"], :name => "I_SCH_JOB_STATUS"

  create_table "script_arguments", :force => true do |t|
    t.integer  "script_id"
    t.string   "argument"
    t.string   "name"
    t.boolean  "is_private"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.string   "position"
    t.boolean  "is_required",                          :null => false
    t.string   "external_resource"
    t.integer  "scripted_resource_id"
    t.string   "list_pairs",           :limit => 4000
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "argument_type"
  end

  add_index "script_arguments", ["script_id"], :name => "index_script_arguments_on_script_id"

  create_table "scripts", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.text     "content"
    t.integer  "integration_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.integer  "template_script_id"
    t.string   "template_script_type"
    t.integer  "tag_id"
    t.string   "authentication"
    t.string   "automation_category",  :null => false
    t.string   "automation_type",      :null => false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "unique_identifier"
    t.string   "render_as"
    t.string   "maps_to"
    t.string   "archive_number"
    t.datetime "archived_at"
    t.string   "file_path"
    t.string   "aasm_state"
  end

  add_index "scripts", ["archive_number"], :name => "index_scripts_on_archive_number"
  add_index "scripts", ["archived_at"], :name => "index_scripts_on_archived_at"
  add_index "scripts", ["integration_id"], :name => "index_scripts_on_integration_id"
  add_index "scripts", ["tag_id"], :name => "index_scripts_on_tag_id"
  add_index "scripts", ["template_script_id"], :name => "index_scripts_on_template_script_id"

  create_table "security_answers", :force => true do |t|
    t.integer  "question_id"
    t.integer  "user_id"
    t.string   "answer"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "security_answers", ["user_id"], :name => "index_security_answers_on_user_id"

  create_table "server_aspect_groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "server_level_id"
  end

  add_index "server_aspect_groups", ["server_level_id"], :name => "sag_server_level_id"

  create_table "server_aspects", :force => true do |t|
    t.integer  "parent_id"
    t.string   "parent_type"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "server_level_id"
    t.text     "description"
  end

  add_index "server_aspects", ["parent_id", "parent_type"], :name => "index_server_aspects_on_parent_id_and_parent_type"
  add_index "server_aspects", ["parent_id"], :name => "index_server_aspects_on_parent_id"
  add_index "server_aspects", ["server_level_id"], :name => "sa_server_level_id"

  create_table "server_aspects_steps", :id => false, :force => true do |t|
    t.integer "server_aspect_id"
    t.integer "step_id"
  end

  add_index "server_aspects_steps", ["server_aspect_id"], :name => "index_server_aspects_steps_on_server_aspect_id"
  add_index "server_aspects_steps", ["step_id"], :name => "index_server_aspects_steps_on_step_id"

  create_table "server_groups", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "active",      :default => true, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "server_groups_servers", :id => false, :force => true do |t|
    t.integer "server_group_id"
    t.integer "server_id"
  end

  add_index "server_groups_servers", ["server_group_id"], :name => "index_server_groups_servers_on_server_group_id"
  add_index "server_groups_servers", ["server_id"], :name => "index_server_groups_servers_on_server_id"

  create_table "server_groups_steps", :id => false, :force => true do |t|
    t.integer "server_group_id"
    t.integer "step_id"
  end

  add_index "server_groups_steps", ["server_group_id"], :name => "index_server_groups_steps_on_server_group_id"
  add_index "server_groups_steps", ["step_id"], :name => "index_server_groups_steps_on_step_id"

  create_table "server_level_properties", :force => true do |t|
    t.integer  "server_level_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "property_id",     :null => false
  end

  add_index "server_level_properties", ["property_id"], :name => "index_server_level_properties_on_property_id"
  add_index "server_level_properties", ["server_level_id"], :name => "index_server_level_properties_on_server_level_id"

  create_table "server_levels", :force => true do |t|
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.string   "name"
  end

  create_table "servers", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",      :default => true, :null => false
    t.string   "dns"
    t.string   "ip_address"
    t.string   "os_platform"
  end

  create_table "servers_steps", :id => false, :force => true do |t|
    t.integer "server_id"
    t.integer "step_id"
  end

  add_index "servers_steps", ["server_id"], :name => "index_servers_steps_on_server_id"
  add_index "servers_steps", ["step_id"], :name => "index_servers_steps_on_step_id"

  create_table "service_now_data", :force => true do |t|
    t.integer  "project_server_id"
    t.string   "name"
    t.string   "sys_id"
    t.string   "table_name"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "service_now_data", ["name"], :name => "name_search"
  add_index "service_now_data", ["project_server_id"], :name => "index_service_now_data_on_project_server_id"
  add_index "service_now_data", ["sys_id"], :name => "foreign_key"
  add_index "service_now_data", ["table_name"], :name => "snow_table"

  create_table "step_execution_conditions", :force => true do |t|
    t.integer  "step_id"
    t.integer  "referenced_step_id"
    t.integer  "property_id"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "runtime_phase_id"
    t.string   "condition_type",     :default => "property"
  end

  add_index "step_execution_conditions", ["property_id"], :name => "index_step_execution_conditions_on_property_id"
  add_index "step_execution_conditions", ["referenced_step_id"], :name => "index_step_execution_conditions_on_referenced_step_id"
  add_index "step_execution_conditions", ["runtime_phase_id"], :name => "index_step_execution_conditions_on_runtime_phase_id"
  add_index "step_execution_conditions", ["step_id"], :name => "index_step_execution_conditions_on_step_id"

  create_table "step_holders", :force => true do |t|
    t.integer  "step_id"
    t.integer  "change_request_id"
    t.integer  "request_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "step_holders", ["change_request_id"], :name => "index_step_holders_on_change_request_id"
  add_index "step_holders", ["request_id"], :name => "index_step_holders_on_request_id"
  add_index "step_holders", ["step_id"], :name => "index_step_holders_on_step_id"

  create_table "step_references", :force => true do |t|
    t.integer  "step_id"
    t.integer  "reference_id"
    t.integer  "owner_object_id"
    t.string   "owner_object_type"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "step_script_arguments", :force => true do |t|
    t.integer  "step_id"
    t.integer  "script_argument_id"
    t.string   "value",                :limit => 4000
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "script_argument_type"
  end

  add_index "step_script_arguments", ["script_argument_id", "script_argument_type"], :name => "step_script_arguments_said_sat"
  add_index "step_script_arguments", ["script_argument_id"], :name => "index_step_script_arguments_on_script_argument_id"
  add_index "step_script_arguments", ["step_id", "script_argument_id"], :name => "script_arguments_by_step"
  add_index "step_script_arguments", ["step_id"], :name => "index_step_script_arguments_on_step_id"

  create_table "steps", :force => true do |t|
    t.integer  "position"
    t.integer  "request_id"
    t.integer  "component_id"
    t.integer  "owner_id"
    t.string   "component_version"
    t.datetime "complete_by"
    t.boolean  "different_level_from_previous", :default => true,        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "estimate"
    t.string   "location_detail"
    t.string   "aasm_state"
    t.datetime "work_started_at"
    t.datetime "work_finished_at"
    t.boolean  "manual",                        :default => true,        :null => false
    t.integer  "work_task_id"
    t.text     "description"
    t.string   "bladelogic_password"
    t.string   "bladelogic_role"
    t.binary   "frozen_owner"
    t.binary   "frozen_component"
    t.binary   "frozen_work_task"
    t.string   "owner_type"
    t.integer  "category_id"
    t.integer  "procedure_id"
    t.integer  "parent_id"
    t.datetime "ready_at"
    t.string   "name"
    t.datetime "start_by"
    t.boolean  "procedure",                     :default => false,       :null => false
    t.integer  "phase_id"
    t.boolean  "should_execute",                :default => true,        :null => false
    t.boolean  "execute_anytime",               :default => false,       :null => false
    t.integer  "runtime_phase_id"
    t.integer  "script_id"
    t.string   "script_type"
    t.boolean  "own_version",                   :default => false
    t.integer  "package_template_id"
    t.text     "package_template_properties"
    t.boolean  "on_plan",                       :default => false
    t.string   "token"
    t.integer  "change_request_id"
    t.integer  "app_id"
    t.string   "completion_state"
    t.integer  "installed_component_id"
    t.integer  "release_content_item_id"
    t.integer  "custom_ticket_id"
    t.integer  "version_tag_id"
    t.boolean  "suppress_notification",         :default => false,       :null => false
    t.boolean  "executor_data_entry",           :default => false,       :null => false
    t.string   "step_type"
    t.boolean  "allow_unattended_promotion",    :default => false,       :null => false
    t.boolean  "execute_on_plan",               :default => false,       :null => false
    t.boolean  "protected_step",                :default => false,       :null => false
    t.string   "default_tab"
    t.binary   "frozen_automation_script"
    t.binary   "frozen_bladelogic_script"
    t.integer  "package_instance_id"
    t.integer  "package_id"
    t.boolean  "create_new_package_instance"
    t.boolean  "latest_package_instance"
    t.string   "related_object_type",           :default => "component"
  end

  add_index "steps", ["app_id"], :name => "index_steps_on_app_id"
  add_index "steps", ["category_id"], :name => "index_steps_on_category_id"
  add_index "steps", ["change_request_id"], :name => "index_steps_on_change_request_id"
  add_index "steps", ["component_id"], :name => "index_steps_on_component_id"
  add_index "steps", ["installed_component_id"], :name => "index_steps_on_installed_component_id"
  add_index "steps", ["owner_id", "owner_type"], :name => "index_steps_on_owner_id_and_owner_type"
  add_index "steps", ["owner_id"], :name => "index_steps_on_owner_id"
  add_index "steps", ["package_id"], :name => "index_steps_on_package_id"
  add_index "steps", ["package_instance_id"], :name => "index_steps_on_package_instance_id"
  add_index "steps", ["package_template_id"], :name => "index_steps_on_package_template_id"
  add_index "steps", ["parent_id"], :name => "index_steps_on_parent_id"
  add_index "steps", ["phase_id"], :name => "index_steps_on_phase_id"
  add_index "steps", ["procedure_id"], :name => "index_steps_on_procedure_id"
  add_index "steps", ["request_id"], :name => "steps_request_id"
  add_index "steps", ["runtime_phase_id"], :name => "index_steps_on_runtime_phase_id"
  add_index "steps", ["script_id"], :name => "scripts_by_step"
  add_index "steps", ["version_tag_id"], :name => "index_steps_on_version_tag_id"
  add_index "steps", ["work_task_id"], :name => "index_steps_on_work_task_id"

  create_table "steps_release_content_items", :force => true do |t|
    t.integer  "step_id"
    t.integer  "release_content_item_id"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "steps_release_content_items", ["release_content_item_id"], :name => "index_steps_release_content_items_on_release_content_item_id"
  add_index "steps_release_content_items", ["step_id"], :name => "index_steps_release_content_items_on_step_id"

  create_table "system_settings", :force => true do |t|
    t.string "name",  :null => false
    t.text   "value", :null => false
  end

  add_index "system_settings", ["name"], :name => "index_system_settings_on_name", :unique => true

  create_table "team_group_app_env_roles", :force => true do |t|
    t.integer  "role_id",                    :null => false
    t.integer  "team_group_id",              :null => false
    t.integer  "application_environment_id", :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  create_table "team_groups", :force => true do |t|
    t.integer  "group_id"
    t.integer  "team_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "team_groups", ["group_id"], :name => "index_teams_groups_on_group_id"
  add_index "team_groups", ["team_id"], :name => "index_teams_groups_on_team_id"

  create_table "teams", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.boolean  "active",     :default => true
  end

  add_index "teams", ["user_id"], :name => "index_teams_on_user_id"

  create_table "temporary_property_values", :force => true do |t|
    t.integer  "property_id",                :null => false
    t.integer  "step_id",                    :null => false
    t.integer  "original_value_holder_id",   :null => false
    t.string   "original_value_holder_type", :null => false
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "request_id"
    t.datetime "deleted_at"
  end

  add_index "temporary_property_values", ["original_value_holder_id", "original_value_holder_type"], :name => "tmppropval_orgvhid_orgvhtype"
  add_index "temporary_property_values", ["original_value_holder_id"], :name => "index_temporary_property_values_on_original_value_holder_id"
  add_index "temporary_property_values", ["property_id"], :name => "index_temporary_property_values_on_property_id"
  add_index "temporary_property_values", ["request_id"], :name => "temp_props_by_request"
  add_index "temporary_property_values", ["step_id"], :name => "index_temporary_property_values_on_step_id"

  create_table "tickets", :force => true do |t|
    t.string   "foreign_id",                               :null => false
    t.string   "name",                                     :null => false
    t.string   "status",            :default => "Unknown", :null => false
    t.string   "ticket_type",       :default => "General"
    t.integer  "project_server_id"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.integer  "app_id"
    t.string   "url"
  end

  add_index "tickets", ["app_id"], :name => "index_tickets_on_app_id"
  add_index "tickets", ["foreign_id"], :name => "index_tickets_on_foreign_id"
  add_index "tickets", ["project_server_id"], :name => "index_tickets_on_project_server_id"
  add_index "tickets", ["status"], :name => "index_tickets_on_status"
  add_index "tickets", ["ticket_type"], :name => "index_tickets_on_ticket_type"

  create_table "transaction_logs", :force => true do |t|
    t.integer  "year"
    t.integer  "month"
    t.string   "file_name"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
  end

  add_index "transaction_logs", ["file_name"], :name => "index_t_logs_on_file_name"
  add_index "transaction_logs", ["month"], :name => "index_t_logs_on_month"
  add_index "transaction_logs", ["year"], :name => "index_t_logs_on_year"

  create_table "uploads", :force => true do |t|
    t.integer  "owner_id"
    t.string   "content_type"
    t.string   "filename"
    t.integer  "size"
    t.integer  "parent_id"
    t.string   "thumbnail"
    t.integer  "width"
    t.integer  "height"
    t.string   "owner_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "attachment"
    t.boolean  "deleted",      :default => false, :null => false
    t.string   "description"
  end

  add_index "uploads", ["attachment"], :name => "index_uploads_on_attachment"
  add_index "uploads", ["deleted"], :name => "I_UPLOADS_DELETED"
  add_index "uploads", ["owner_id"], :name => "index_uploads_on_owner_id"
  add_index "uploads", ["owner_type"], :name => "index_uploads_on_owner_type"
  add_index "uploads", ["user_id"], :name => "index_uploads_on_user_id"

  create_table "user_apps", :force => true do |t|
    t.integer  "user_id"
    t.integer  "app_id"
    t.text     "roles"
    t.boolean  "visible",    :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "user_apps", ["app_id"], :name => "index_user_apps_on_app_id"
  add_index "user_apps", ["user_id"], :name => "index_user_apps_on_user_id"

  create_table "user_groups", :force => true do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_groups", ["group_id"], :name => "index_user_groups_on_group_id"
  add_index "user_groups", ["user_id"], :name => "index_user_groups_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email",                                    :default => ""
    t.string   "first_name"
    t.string   "last_name"
    t.string   "encrypted_password",        :limit => 128, :default => ""
    t.string   "password_salt",                            :default => ""
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                                    :default => false
    t.boolean  "active",                                   :default => true,        :null => false
    t.text     "old_roles"
    t.string   "employment_type",                          :default => "permanent", :null => false
    t.string   "location"
    t.integer  "max_allocation",                           :default => 100,         :null => false
    t.boolean  "system_user",                              :default => true,        :null => false
    t.string   "type"
    t.boolean  "root",                                     :default => false,       :null => false
    t.string   "time_zone"
    t.string   "list_order",                               :default => "desc"
    t.boolean  "first_time_login",                         :default => true
    t.boolean  "is_reset_password",                        :default => false
    t.text     "calendar_preferences"
    t.datetime "last_response_at"
    t.boolean  "global_access",                            :default => false
    t.integer  "first_day_on_calendar",                    :default => 0
    t.datetime "remember_created_at"
    t.string   "contact_number"
    t.string   "api_key"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer  "sign_in_count",                            :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
  end

  add_index "users", ["admin"], :name => "I_USERS_ADMIN"
  add_index "users", ["api_key"], :name => "index_users_on_api_key"
  add_index "users", ["email"], :name => "I_USERS_EMAIL"
  add_index "users", ["first_name"], :name => "I_USERS_FIRST"
  add_index "users", ["id", "type"], :name => "index_users_on_id_and_type"
  add_index "users", ["last_name", "first_name"], :name => "I_USERS_LAST_FIRST"
  add_index "users", ["last_name"], :name => "I_USERS_LAST"
  add_index "users", ["last_response_at"], :name => "I_USERS_ON_LRA"
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["root"], :name => "I_USERS_ROOT"
  add_index "users", ["system_user"], :name => "I_USERS_SYSTEM_USR"

  create_table "version_tags", :force => true do |t|
    t.string   "name",                   :null => false
    t.integer  "app_id"
    t.integer  "app_env_id"
    t.integer  "installed_component_id"
    t.string   "artifact_url"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
    t.string   "archive_number"
    t.datetime "archived_at"
  end

  add_index "version_tags", ["app_env_id"], :name => "index_version_tags_on_app_env_id"
  add_index "version_tags", ["app_id"], :name => "index_version_tags_on_app_id"
  add_index "version_tags", ["archive_number"], :name => "index_version_tags_on_archive_number"
  add_index "version_tags", ["archived_at"], :name => "index_version_tags_on_archived_at"
  add_index "version_tags", ["installed_component_id"], :name => "index_version_tags_on_installed_component_id"

  create_table "work_tasks", :force => true do |t|
    t.string   "name",           :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.string   "archive_number"
    t.datetime "archived_at"
  end

  add_index "work_tasks", ["archive_number"], :name => "index_work_tasks_on_archive_number"
  add_index "work_tasks", ["archived_at"], :name => "index_work_tasks_on_archived_at"
  add_index "work_tasks", ["name"], :name => "index_work_tasks_on_name", :unique => true
  add_index "work_tasks", ["position"], :name => "index_work_tasks_on_position"

  create_table "workstreams", :force => true do |t|
    t.integer  "resource_id",   :null => false
    t.integer  "activity_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "activity_role"
  end

  add_index "workstreams", ["activity_id"], :name => "index_workstreams_on_activity_id"
  add_index "workstreams", ["resource_id"], :name => "index_workstreams_on_resource_id"

end
