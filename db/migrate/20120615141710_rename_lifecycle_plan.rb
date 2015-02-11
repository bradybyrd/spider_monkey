class RenameLifecyclePlan < ActiveRecord::Migration
  def up

    # activities related changes
    remove_index "activities", ["lifecycle_stage_id"] # :name => "index_activities_on_lifecycle_stage_id"
    rename_column "activities", :lifecycle_stage_id, :plan_stage_id
    add_index "activities", ["plan_stage_id"]#, :name => "index_activities_on_plan_stage_id"

    # build_contents related changes
    remove_index "build_contents", ["lifecycle_id"] #, :name => "index_build_contents_on_lifecycle_id"
    rename_column "build_contents", :lifecycle_id, :plan_id
    add_index "build_contents", ["plan_id"] #, :name => "index_build_contents_on_plan_id"

    # change_requests related changes
    remove_index "change_requests", ["lifecycle_id"] #, :name => "index_change_requests_on_lifecycle_id"
    rename_column "change_requests", :lifecycle_id, :plan_id
    add_index "change_requests", ["plan_id"] #, :name => "index_change_requests_on_plan_id"

    # integration_csvs related changes
    remove_index "integration_csvs", ["lifecycle_id"] #, :name => "index_integration_csvs_on_lifecycle_id"
    rename_column "integration_csvs", :lifecycle_id, :plan_id
    add_index "integration_csvs", ["plan_id"] #, :name => "index_integration_csvs_on_plan_id"

    # lc_stages_request_templates related changes
    rename_column "lc_stages_request_templates", :lifecycle_stage_id, :plan_stage_id
    add_index "lc_stages_request_templates", ["plan_stage_id"] #, :name => "index_psrt_on_plan_stage_id"
    add_index "lc_stages_request_templates", ["request_template_id"] #, :name => "index_psrt_on_request_template_id"

    if !OracleAdapter
      rename_table "lc_stages_request_templates", "p_stages_request_templates"
    else
      # Cheap trick because for oracle seq name is made shorter and rename_table just couldn't handle it.
      ActiveRecord::Base.connection.execute("rename lc_stages_request_templates to p_stages_request_templates");
      ActiveRecord::Base.connection.execute("rename lc_stages_request_template_seq to p_stages_request_templates_seq");
    end

    # lifecycle_members related changes
    remove_index "lifecycle_members", ["lifecycle_id"] #, :name => "index_lifecycle_members_on_lifecycle_id"
    remove_index "lifecycle_members", :name => "i_lm_lsi_pos"
    remove_index "lifecycle_members", ["lifecycle_stage_id"] #, :name => "index_lifecycle_members_on_lifecycle_stage_id"
    remove_index "lifecycle_members", :name => "i_lm_lssi"
    rename_column "lifecycle_members", :lifecycle_id, :plan_id
    rename_column "lifecycle_members", :lifecycle_stage_id, :plan_stage_id
    rename_column "lifecycle_members", :lifecycle_stage_status_id, :plan_stage_status_id
    add_index "lifecycle_members", ["plan_id"] #, :name => "index_plan_members_on_plan_id"
    add_index "lifecycle_members", ["plan_stage_id", "position"] #, :name => "i_pm_psi_pos"
    add_index "lifecycle_members", ["plan_stage_id"] #, :name => "index_plan_members_on_psi"
    add_index "lifecycle_members", ["plan_stage_status_id"] #, :name => "i_pm_pssi"
    rename_index "lifecycle_members", "i_lm_dlfp", "i_plan_member_on_dlfp"
    #rename_index "lifecycle_members", "index_lifecycle_members_on_parallel", "i_plan_members_on_parallel"
    rename_table "lifecycle_members", "plan_members"

    # lifecycle_stage_dates related changes
    remove_index "lifecycle_stage_dates", ["lifecycle_id"] #, :name => "index_lifecycle_stage_dates_on_lifecycle_id"
    remove_index "lifecycle_stage_dates", ["lifecycle_stage_id"] #, :name => "index_lifecycle_stage_dates_on_lifecycle_stage_id"
    rename_column "lifecycle_stage_dates", :lifecycle_id, :plan_id
    rename_column "lifecycle_stage_dates", :lifecycle_stage_id, :plan_stage_id
    add_index "lifecycle_stage_dates", ["plan_id"] #, :name => "index_plan_stage_dates_on_plan_id"
    add_index "lifecycle_stage_dates", ["plan_stage_id"] #, :name => "index_plan_stage_dates_on_psi"
    rename_index "lifecycle_stage_dates", "i_lc_st_dates_ed", "i_plan_stage_dates_end_date"
    rename_index "lifecycle_stage_dates", "i_lc_st_sd_ed", "i_plan_stage_dates_start_end"
    rename_table "lifecycle_stage_dates", "plan_stage_dates"

    # lifecycle_stage_statuses related changes
    remove_index "lifecycle_stage_statuses", :name => "i_lc_st_status_lsi_pos" # Keep name because earlier migration sets same name.
    rename_column "lifecycle_stage_statuses", :lifecycle_stage_id, :plan_stage_id
    add_index "lifecycle_stage_statuses", ["plan_stage_id", "position"] #, :name => "index_pss_on_psi_pos"
    rename_index "lifecycle_stage_statuses", "i_lc_st_status_lsi_name", "i_plan_pss_name"
    rename_table "lifecycle_stage_statuses", "plan_stage_statuses"

    # lifecycle_stages related changes
    remove_index "lifecycle_stages", ["lifecycle_template_id"] #, :name => "index_lifecycle_stages_on_lifecycle_template_id"
    rename_column "lifecycle_stages", :lifecycle_template_id, :plan_template_id
    add_index "lifecycle_stages", ["plan_template_id"] #, :name => "index_ps_on_pt"
    rename_index "lifecycle_stages", "i_lc_stages_auto_start", "i_plan_stages_auto_start"
    rename_index "lifecycle_stages", "i_lc_stages_name", "i_plan_stages_name"
    rename_index "lifecycle_stages", "i_lc_stages_position", "i_plan_stages_position"
    rename_table "lifecycle_stages", "plan_stages"

    # lifecycle_teams related changes
    remove_index "lifecycle_teams", ["lifecycle_id"] #, :name => "index_lifecycle_teams_on_lifecycle_id"
    rename_column "lifecycle_teams", :lifecycle_id, :plan_id
    add_index "lifecycle_teams", ["plan_id"] #, :name => "index_plan_teams_on_plan_id"
    rename_table "lifecycle_teams", "plan_teams"

    # lifecycle_templates related changes
    rename_index "lifecycle_templates", "i_lc_temp_is_auto", "i_pt_is_auto"
    rename_index "lifecycle_templates", "i_lc_temp_name","i_pt_name"
    rename_index "lifecycle_templates", "i_lc_temp_tt", "i_pt_template_type"
    rename_table "lifecycle_templates", "plan_templates"

    # lifecycles related changes
    rename_column "lifecycles", :lifecycle_template_id, :plan_template_id
    #rename_index "lifecycles", "index_lifecycles_on_lifecycle_template_id", "index_plans_on_plan_template_id"
    #rename_index "lifecycles", "index_lifecycles_on_release_id", "index_plans_on_release_id"
    #rename_index "lifecycles", "index_lifecycles_on_release_manager_id", "index_plans_on_release_manager_id"
    add_index "lifecycles", :aasm_state #, :name => 'index_plans_on_aasm_state'
    add_index "lifecycles", :name #, :name => 'index_plans_on_name'
    rename_table "lifecycles", "plans"

    # queries related changes
    remove_index "queries", ["lifecycle_id"] #, :name => "index_queries_on_lifecycle_id"
    rename_column "queries", :lifecycle_id, :plan_id
    add_index "queries", ["plan_id"] #, :name => "index_queries_on_plan_id"

    # release_content_items related changes
    remove_index "release_content_items", ["lifecycle_id"] #, :name => "index_release_content_items_on_lifecycle_id"
    rename_column "release_content_items", :lifecycle_id, :plan_id
    add_index "release_content_items", ["plan_id"] #, :name => "index_release_content_items_on_plan_id"

    # release_contents related changes
    remove_index "release_contents", ["lifecycle_id"] #, :name => "index_release_contents_on_lifecycle_id"
    rename_column "release_contents", :lifecycle_id, :plan_id
    add_index "release_contents", ["plan_id"] #, :name => "index_release_contents_on_plan_id"

    # requests related changes
    remove_index "requests", ["lifecycle_member_id"] #, :name => "index_requests_on_lifecycle_member_id"
    rename_column "requests", :lifecycle_member_id, :plan_member_id
    add_index "requests", ["plan_member_id"] #, :name => "index_requests_on_plan_member_id"

    # runs related changes
    remove_index "runs", :name => "index_runs_on_lifecycle_id"
    remove_index "runs", ["lifecycle_stage_id"] #, :name => "index_runs_on_lifecycle_stage_id"
    rename_column "runs", :lifecycle_id, :plan_id
    rename_column "runs", :lifecycle_stage_id, :plan_stage_id
    add_index "runs", ["plan_id"] #, :name => "index_runs_on_plan_id"
    add_index "runs", ["plan_stage_id"] #, :name => "index_runs_on_plan_stage_id"

    # steps related changes
    rename_column "steps", :on_lifecycle, :on_plan
  end

  def down

    # activities related changes
    remove_index "activities", :name => "index_activities_on_plan_stage_id"
    rename_column "activities", :plan_stage_id, :lifecycle_stage_id
    add_index "activities", ["lifecycle_stage_id"], :name => "index_activities_on_lifecycle_stage_id"

    # build_contents related changes
    remove_index "build_contents", :name => "index_build_contents_on_plan_id"
    rename_column "build_contents", :plan_id, :lifecycle_id
    add_index "build_contents", ["lifecycle_id"], :name => "index_build_contents_on_lifecycle_id"

    # change_requests related changes
    remove_index "change_requests", :name => "index_change_requests_on_plan_id"
    rename_column "change_requests", :plan_id, :lifecycle_id
    add_index "change_requests", ["lifecycle_id"], :name => "index_change_requests_on_lifecycle_id"

    # change_requests related changes
    remove_index "integration_csvs", ["plan_id"]
    rename_column "integration_csvs", :plan_id, :lifecycle_id
    add_index "integration_csvs", ["lifecycle_id"], :name => "index_integration_csvs_on_lifecycle_id"

    # lc_stages_request_templates related changes
    rename_table "plan_stages_request_templates", "lc_stages_request_templates"
    rename_column "lc_stages_request_templates", :plan_stage_id, :lifecycle_stage_id
    remove_index "lc_stages_request_templates", :name => "index_psrt_on_plan_stage_id"
    remove_index "lc_stages_request_templates", :name => "index_psrt_on_request_template_id"

    # lifecycle_members related changes
    rename_table "plan_members", "lifecycle_members"
    remove_index "lifecycle_members", :name => "index_plan_members_on_plan_id"
    remove_index "lifecycle_members", :name => "i_pm_psi_pos"
    remove_index "lifecycle_members", :name => "index_plan_members_on_psi"
    remove_index "lifecycle_members", :name => "i_pm_pssi"
    rename_column "lifecycle_members", :plan_id, :lifecycle_id
    rename_column "lifecycle_members", :plan_stage_id, :lifecycle_stage_id
    rename_column "lifecycle_members", :plan_stage_status_id, :lifecycle_stage_status_id
    add_index "lifecycle_members", ["lifecycle_id"], :name => "index_lifecycle_members_on_lifecycle_id"
    add_index "lifecycle_members", ["lifecycle_stage_id", "position"], :name => "i_lm_lsi_pos"
    add_index "lifecycle_members", ["lifecycle_stage_id"], :name => "index_lifecycle_members_on_lifecycle_stage_id"
    add_index "lifecycle_members", ["lifecycle_stage_status_id"], :name => "i_lm_lssi"
    rename_index "lifecycle_members", "i_plan_member_on_dlfp", "i_lm_dlfp"
    rename_index "lifecycle_members", "i_plan_members_on_parallel", "index_lifecycle_members_on_parallel"

    # lifecycle_stage_dates related changes
    rename_table "plan_stage_dates", "lifecycle_stage_dates"
    remove_index "lifecycle_stage_dates", :name => "index_plan_stage_dates_on_plan_id"
    remove_index "lifecycle_stage_dates", :name => "index_plan_stage_dates_on_psi"
    rename_column "lifecycle_stage_dates", :plan_id, :lifecycle_id
    rename_column "lifecycle_stage_dates", :plan_stage_id, :lifecycle_stage_id
    add_index "lifecycle_stage_dates", ["lifecycle_id"], :name => "index_lifecycle_stage_dates_on_lifecycle_id"
    add_index "lifecycle_stage_dates", ["lifecycle_stage_id"], :name => "index_lifecycle_stage_dates_on_lifecycle_stage_id"
    rename_index "lifecycle_stage_dates", "i_plan_stage_dates_end_date", "i_lc_st_dates_ed"
    rename_index "lifecycle_stage_dates", "i_plan_stage_dates_start_end", "i_lc_st_sd_ed"

    # lifecycle_stage_statuses related changes
    rename_table "plan_stage_statuses", "lifecycle_stage_statuses"
    rename_index "lifecycle_stage_statuses", "i_plan_pss_name", "i_lc_st_status_lsi_name"
    remove_index "lifecycle_stage_statuses", :name => "index_pss_on_psi_pos"
    rename_column "lifecycle_stage_statuses", :plan_stage_id, :lifecycle_stage_id
    add_index "lifecycle_stage_statuses", ["lifecycle_stage_id", "position"], :name => "i_lc_st_status_lsi_pos"

    # lifecycle_stages related changes
    rename_table "plan_stages", "lifecycle_stages"
    remove_index "lifecycle_stages", :name => "index_ps_on_pt"
    rename_column "lifecycle_stages", :plan_template_id, :lifecycle_template_id
    add_index "lifecycle_stages", ["lifecycle_template_id"], :name => "index_lifecycle_stages_on_lifecycle_template_id"
    rename_index "lifecycle_stages", "i_plan_stages_auto_start", "i_lc_stages_auto_start"
    rename_index "lifecycle_stages", "i_plan_stages_name", "i_lc_stages_name"
    rename_index "lifecycle_stages", "i_plan_stages_position", "i_lc_stages_position"

    # lifecycle_teams related changes
    rename_table "plan_teams", "lifecycle_teams"
    remove_index "lifecycle_teams", :name => "index_plan_teams_on_plan_id"
    rename_column "lifecycle_teams", :plan_id, :lifecycle_id
    add_index "lifecycle_teams", ["lifecycle_id"], :name => "index_lifecycle_teams_on_lifecycle_id"

    # lifecycle_templates related changes
    rename_table "plan_templates", "lifecycle_templates"
    rename_index "lifecycle_templates", "i_pt_is_auto", "i_lc_temp_is_auto"
    rename_index "lifecycle_templates", "i_pt_name", "i_lc_temp_name"
    rename_index "lifecycle_templates", "i_pt_template_type", "i_lc_temp_tt"

    # lifecycles related changes
    rename_table "plans", "lifecycles"
    rename_column "lifecycles", :plan_template_id, :lifecycle_template_id
    rename_index "lifecycles", "index_plans_on_plan_template_id", "index_lifecycles_on_lifecycle_template_id"
    rename_index "lifecycles", "index_plans_on_release_id", "index_lifecycles_on_release_id"
    rename_index "lifecycles", "index_plans_on_release_manager_id", "index_lifecycles_on_release_manager_id"
    remove_index "lifecycles", :name => 'index_plans_on_aasm_state'
    remove_index "lifecycles", :name => 'index_plans_on_name'

    # queries related changes
    remove_index "queries", :name => "index_queries_on_plan_id"
    rename_column "queries", :plan_id, :lifecycle_id
    add_index "queries", ["lifecycle_id"], :name => "index_queries_on_lifecycle_id"

    # release_content_items related changes
    remove_index "release_content_items", :name => "index_release_content_items_on_plan_id"
    rename_column "release_content_items", :plan_id, :lifecycle_id
    add_index "release_content_items", ["lifecycle_id"], :name => "index_release_content_items_on_lifecycle_id"

    # release_contents related changes
    remove_index "release_contents", :name => "index_release_contents_on_plan_id"
    rename_column "release_contents", :plan_id, :lifecycle_id
    add_index "release_contents", ["lifecycle_id"], :name => "index_release_contents_on_lifecycle_id"

    # requests related changes
    remove_index "requests", :name => "index_requests_on_plan_member_id"
    rename_column "requests", :plan_member_id, :lifecycle_member_id
    add_index "requests", ["lifecycle_member_id"], :name => "index_requests_on_lifecycle_member_id"

    #runs related changes
    remove_index "runs", :name => "index_runs_on_plan_id"
    remove_index "runs", :name => "index_runs_on_plan_stage_id"
    rename_column "runs", :plan_id, :lifecycle_id
    rename_column "runs", :plan_stage_id, :lifecycle_stage_id
    add_index "runs", ["lifecycle_id"], :name => "index_runs_on_lifecycle_id"
    add_index "runs", ["lifecycle_stage_id"], :name => "index_runs_on_lifecycle_stage_id"

    # steps related changes
    rename_column "steps", :on_plan, :on_lifecycle
  end
end
