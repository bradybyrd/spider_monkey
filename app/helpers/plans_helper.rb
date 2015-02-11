################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module PlansHelper

  ["continuous_integration", "release_plan", "multi_item", "deploy"].each do |lc_type|
    define_method("#{lc_type}_plan_present?"){Plan.with_plan_template("#{lc_type}").count > 0}
  end

  def render_request_form f, request, plan, environments
    render :partial => 'requests/form',
      :locals => { :f => f,
      :request => request,
      :human_date_format => GlobalSettings.human_date_format,
      :from_app_plan => plan.applications.any?,
      :environments => environments,
      :from_plan => true }
  end

  def select_list_for_plans_templates(plan_templates=[])
    select :plan, :plan_template_id, plan_templates.collect { |l| [l.to_label, l.id ]}, { :include_blank => 'Select' }
  end

  def select_list_for_members(members=[])
    select_tag :member_id, options_for_select(["Select"])
  end

  def request_color_code_for_stage(request_state)
    { "started" => "round_box_lc_started", "created" => "round_box_lc_created", "planned" => "round_box_lc_planned", "problem" => "round_box_lc_problem", "hold" => "round_box_lc_hold", "cancelled" => "round_box_lc_cancelled", "complete" => "round_box_lc_complete", "deleted" => "round_box_lc_deleted" }[request_state]
  end

  def request_color_code_for_label(request_state)
    {"started" => "auto_started_Request", "created" => "auto_created_Request", "planned" => "auto_planned_Request", "problem" => "auto_problem_Request", "hold" => "auto_hold_Request", "cancelled" => "auto_cancelled_Request", "complete" => "auto_complete_Request", "deleted" => "auto_deleted_Request"}[request_state]
  end

  def selected_lifecyle_tab(params_template_type, template_type)
    if params_template_type.eql?(template_type)
      return "selected"
    end
  end

  def my_date(app_date)
    return Time.parse(app_date).strftime("%m/%d/%Y")
  end

  def my_datetime(app_date)
    Time.parse(app_date.to_s).strftime(GlobalSettings[:default_date_format]) rescue ''
  end

  # Code to display stage icon 'A' or 'M'
  def display_stage_icon(autostart)
    return autostart ? "A" : "M"
  end

  def date_for_release(plan)
    return plan.release_date.blank? ? Date.today : plan.release_date
  end

  #TODO These methods do not use, you can delete it
  def multi_plan_template_options
    @plan_templates = PlanTemplate.unarchived.find_all_by_template_type('multi_item')
    return @plan_templates.collect { |lt| [lt.name, lt.id]}
  end

  def stage_timeframe(stage, grouped_members, plan=nil)
    if plan
      requests = Request.in_stage_of_plan(plan.id, stage.id)
    else
      requests = grouped_members[stage.id]
    end
    return if requests.blank?
    planned_start= ''
    due_by = ''
    requests_dates = grouped_members[stage.id].map{|member| member.request}.compact.collect{
      |r| [r.scheduled_at, r.target_completion_at]}
    earliest_planned_start = requests_dates.collect {|rd| rd[0]}.compact.min
    latest_due_by = requests_dates.collect {|rd| rd[1]}.compact.max
    planned_start += "Planned Start - #{default_format_date(earliest_planned_start)}" if earliest_planned_start
    due_by += "Due By - #{default_format_date(latest_due_by)}" if latest_due_by
    return "#{planned_start} #{due_by}"
  end

  #TODO These methods do not use, you can delete it
  def stage_plan_dates(stage)
    return unless stage
    planned_start = "Planned Start - #{default_format_date(stage.start_date)}" if stage.start_date
    due_by = "Due By - #{default_format_date(stage.end_date)}" if stage.end_date
    return "#{planned_start} #{due_by}"
  end

  def release_calendar_options
    [
      ['Current year to end', "#{Date.today.beginning_of_month},#{Date.today.end_of_year}"],
      ['Rolling 3 months', "#{Date.today.beginning_of_month},#{(Date.today + 2.month).end_of_month}"],
      ['Rolling 6 months', "#{Date.today.beginning_of_month},#{(Date.today + 5.month).end_of_month}"],
      ['Year to date', "#{Date.today.beginning_of_year},#{Date.today}"],
      ['Last Year', "#{Date.today.strftime('%Y').to_i-1}-01-01,#{Date.today.strftime('%Y').to_i-1}-12-31"],
      ['Next Year', "#{Date.today.strftime('%Y').to_i+1}-01-01,#{Date.today.strftime('%Y').to_i+1}-12-31"]
    ]
  end

  #TODO These methods do not use, you can delete it
  def link_to_all_activities(plan)
    @plan_activities = plan.activities
    links = []
    @plan_activities.sort_by(&:name).each do |activity|
      links << link_to_function(h(activity.name), "loadRequests('#{plan.id}', '#{activity.id}')")
    end
  end

  #TODO These methods do not use, you can delete it
  def last_member_of_stage(stage)
    @stage_members_last = stage.members.last
  end

  def status_label(plan)
    content_tag(:span, plan.aasm.current_state.to_s.humanize,
      :class => "#{plan.aasm.current_state}RequestStep state lc_state")
  end

  #TODO These methods do not use, you can delete it
  def get_tab_name(tab_id)
    @tab = Plan::TABS[tab_id]
  end

  def label_value(name, val)
    "<span class='name_pair'>#{name}: </span><span class='value_pair'>#{val}"
  end

  def plan_environments_list(plan, app)
    return plan.environments_for_app(app.id).map(&:name).join(", ")
  end

  def flowchart_stages_for_plan(plan)
    my_results = []
    plan.stages.try(:each) do |stage|
      request_count = Request.in_stage_of_plan(plan.id, stage.id).count
      my_results << content_tag(:span, "#{truncate(stage.try(:name), :length => 25)} #{ count_label(request_count) }",
        :title => "#{stage.auto_start? ? 'Automatic' : 'Manual'} stage with #{pluralize(request_count, 'request')}.",
        :class => request_count > 0 ? "life_cycle plan_stage_circle round_box_lc_created" : "life_cycle plan_stage_circle round_box_lc_no_request")
    end
    return my_results.join(content_tag(:span, "&nbsp; > &nbsp;".html_safe, :class => "plan_arrow"))
  end

  def count_label(count = 0)
    if count > 0
      "(#{count})"
    else
      ""
    end
  end

  def request_name_links_for_app(plan,app_id)
    plan.requests.with_app_id(app_id).map{ |req| link_to(req.number, edit_request_path(req.number), :title => req.try(:request_label)) }.join(" | ")
  end

  def run_name_links_for_app(plan,app_id)
    run_links = []
    plan.runs.each do |run|
      run_apps = run.requests.map(&:app_ids).flatten.uniq
      run_links << link_to(truncate(run.name, :length => 20), "#{plan_path(:id => plan.id)}?run_id=#{run.id}&stage_#{run.plan_stage_id}") if run_apps.include?(app_id)
    end
    if run_links.empty?
      return " - "
    else
      run_links.join(" | ")
    end
  end

  def plan_label(request)
    my_label = []
    unless request.plan.nil?
      my_label << request.plan.name
      my_label << (request.plan_member.try(:plan_stage_id).to_i == 0 ? 'Unassigned' : request.plan_member.try(:stage).try(:name))
      my_label << image_tag('icons/lock.png') if cannot?(:edit, request)
      my_label << request.plan_member.run.name unless request.plan_member.nil? or request.plan_member.run.nil?
    end
    return my_label.join(": ").html_safe
  end

  def available_state_buttons_for_run(run)
    disable_flag = run.plan.archived?
    my_results = []
    unless run.plan_members.blank?
      if can? :reorder_run, run.plan
        my_results << button_to( 'Reorder Run',
                                 reorder_members_plan_run_path(:plan_id => run.plan, :id => run.id),
                                 :method => :get,
                                 :class => "button",
                                 disabled: disable_flag ) if %w(created planned held).include?(run.aasm_state)
      end
      my_results << button_to_plan_run(run, disable_flag) if %w(created cancelled).include?(run.aasm_state)
      if can? :start_run, run.plan
        my_results << button_to('Start Run', start_plan_run_path(:plan_id => run.plan, :id => run.id), {
                                  :method => :put, :class => "button", disabled: disable_flag,
                                  remote: true, form: {class: "start_run"} }
                               ) if %w(held planned).include?(run.aasm_state)
      end
      if can? :hold_run, run.plan
        my_results << button_to('Hold Run', plan_run_path(:plan_id => run.plan, :id => run.id, 'run[aasm_event]' => 'hold'), :method => :put, :class => "button", disabled: disable_flag ) if %w(started).include?(run.aasm_state)
      end
      if can? :cancel_run, run.plan
        my_results << button_to('Cancel Run', plan_run_path(:plan_id => run.plan, :id => run.id, 'run[aasm_event]' => 'cancel'), :method => :put, :class => "button", disabled: disable_flag ) if %w(created planned started held blocked).include?(run.aasm_state)
      end
    end
    if can? :delete_run, run.plan
      my_results << button_to('Delete Run', plan_run_path(:plan_id => run.plan, :id => run.id, 'run[aasm_event]' => 'delete'), :method => :put, :class => "button", disabled: disable_flag, :confirm => 'Are you sure you want to delete this run?') if %w(created cancelled completed).include?(run.aasm_state)
    end

    my_results.reverse.join
  end

  def button_to_plan_run(run, disable_flag)
    if can? :plan_run, run.plan
      if run.requests_have_notices?
        button_to('Plan Run', plan_run_path(:plan_id => run.plan, :id => run.id, 'run[aasm_event]' => 'plan_it'),
                                :method => :put, :class => 'button', disabled: disable_flag,
                                confirm: "#{run.requests_notices_message}. \nYou won't be able to start request(s). Do you want to continue?" )
      else
        button_to('Plan Run', plan_run_path(:plan_id => run.plan, :id => run.id, 'run[aasm_event]' => 'plan_it'),
                                :method => :put, :class => 'button', disabled: disable_flag )
      end
    end
  end

  def parallel_toggle_image(member)
    higher_item = member.higher_item
    lower_item = member.lower_item

    # check if it is parallel or serial or the first item
    if member.different_level_from_previous || higher_item.nil?
      # show an hourglass if this member is the last in the stack and serial, or the first and the next item is serial
      if lower_item.nil? || ((higher_item.nil? && lower_item.try(:different_level_from_previous)) || lower_item.try(:different_level_from_previous))
        icon = 'icons/hourglass.png'
        message = "##{member.position}. Serial task."
      else
        icon = 'icons/hourglass_go.png'
        message = "##{member.position}. Parallel tasks start here."
      end
    else
      icon = 'icons/arrow_down.png'
      message = "##{member.position}. Parallel task."
    end
    image_tag(icon, :name => nil, :title => message )
  end

  def dates_for_env_app(environment_id, app_id, plan_id)
    PlanEnvAppDate.where("environment_id = ? and app_id = ? and plan_id = ?", environment_id, app_id, plan_id).first
  end

  def requests_available_to_current_user(grouped_members, stage, run=nil)
    members_requests(grouped_members, stage).select( &available?(run) )
  end

  def members_requests(grouped_members, stage)
    members_for_stage(grouped_members, stage).map(&:request).compact
  end

  def members_for_stage(grouped_members, stage)
    grouped_members[stage.try(:id).to_i] || []
  end

  def available?(run)
    ->(request) { (run.blank? || run.requests.pluck(:id).include?(request.id)) && request.is_visible?(current_user, current_user.app_ids) }
  end
end

