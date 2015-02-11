################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module DashboardHelper
  def request_filter_options(model, filters, attribute_name=nil)
    sort_column = if model == User
      if PostgreSQLAdapter || OracleAdapter
        "users.last_name || ', ' || users.first_name"
      else
        "users.last_name + ', ' + users.first_name"
      end
    else
      "name"
    end
    filters ||= {}
    value = if attribute_name.blank?
      if filters["#{model.to_s.underscore}_id"].kind_of?(Array)
        filters["#{model.to_s.underscore}_id"].flatten
      else
        filters["#{model.to_s.underscore}_id"]
      end
    else
      filters["#{attribute_name}"]
    end

    if value.kind_of? Array
      value = value.map {|x| x.to_i}
    else
      value = value.to_i
    end

    model_records = if model.is_a?(Array)
      model
    else
      if model.respond_to? :active_and_used
        model.active_and_used
      else
        model.active.all(:order => sort_column)
      end
    end

    "<option></option>" + options_from_collection_for_select(model_records, :id, :name, value)
  end

  def whose_requests
    !params[:for_dashboard] || @show_all ? 'Requests' : 'My Requests'
  end

  def class_per_page_path(tab)
    tab == partial_as_per_page_path ? "current" : ""
   end

  def partial_as_per_page_path
    return "calendar" if @page_path.nil?
    case
      when @page_path.match(/promotion_requests/); "promotions"
      when @page_path.match(/my-dashboard/); "requests"
      when @page_path.match(/dashboard/); "currently_running_steps"
      when @page_path.match(/currently_running/); "currently_running_steps"
      when @page_path.match(/request_dashboard/); "requests"
      when @page_path.match(/calendars/); "calendar"
    end
  end

  def find_releases(requests, entity=nil)
    unless requests.empty?
      release_name = []
      request_ids = requests.map(&:id).join(",")
      requests_id = ActivityLog.dashboard_requests_ids(request_ids)
      requests_id.each_with_index do |r, ri|
        release = Release.unarchived.includes(:plans).find_by_id(r.release_id)
        release_name << link_to(release.name, plan_path(r.plan_id)) if can?(:inspect, Plan.new)
      end
      release_name.uniq!
    end
    if release_name && entity && release_name.size > 3
      release_name[0] = "<span id='#{entity.class.to_s}_releases_#{entity.id}'>" + release_name[0]
      release_name[2] += "</span>".html_safe
      release_name[3] = "<span class='dn' id='#{entity.class.to_s}_more_releases_#{entity.id}'>" + release_name[3]
      release_name[release_name.size - 1] += "</span>"
      release_name[release_name.size - 1] += link_to_function("...", "toggleReleaseNames('#{entity.id}', '#{entity.class.to_s}')")
      release_name.join(", ").html_safe
    elsif release_name.present? && entity
      releases = "<span id='#{entity.class.to_s}_releases_#{entity.id}'>" + release_name[0]
      releases += ", #{release_name[1]}" if release_name.size > 1
      releases += ", #{release_name[2]}" if release_name.size > 2
      releases += "</span>"
      releases.html_safe
    else
      "-"
    end
  end

  def request_list_preferences
    @request_list_preferences = current_user.request_list_preferences.active
  end

  def plan_run_select_list_with_stage
    aasm_state = ["completed","planned", "started", "held", "cancelled", "created"]
    grouped_options = {}
    Plan.entitled(current_user).find(:all, :include => {:runs => :plan_stage}, :conditions => {:aasm_state => aasm_state}).each do |plan|
      all_runs = plan.runs
      plan_stage_id = all_runs.map(&:plan_stage_id).uniq
      plan_stage_id.each_with_index do |stage_id, i|
        instance_variable_set("@group_#{i}", [])
        all_runs.each {|run| instance_variable_get("@group_#{i}").push(run) if run.plan_stage_id == stage_id}
      end
      plan_stage_id.size.times do |i|
        run_options = []
        opt_group = ""
        instance_variable_get("@group_#{i}").each_with_index do |run, i|
          opt_group = "#{plan.name}" + "-" + "#{run.plan_stage.name}" if i == 0
          run_options << [run.name, run.id]
        end
        grouped_options.merge!(opt_group => run_options)
      end
    end
    grouped_options_for_select(grouped_options)
  end

end
