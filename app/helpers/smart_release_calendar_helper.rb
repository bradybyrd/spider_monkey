################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

module SmartReleaseCalendarHelper

  # colors cycled through on the calendar
  # app1 through app15 are the class names
  NUMBER_OF_REQUEST_CLASSES_ON_CALENDAR = 15

  # display a request, for use inside a day td in the schedule calendar
  def show_request(req)
    app_name = (req.apps ? req.app_name : nil)
    @app_names ||= []
    app_name.each do |an|
      @app_names << an unless @app_names.include?(an)
    end

    if app_name.blank?
      class_number = (0 % NUMBER_OF_REQUEST_CLASSES_ON_CALENDAR).next
    else
      class_number = (@app_names.index(app_name.first) % NUMBER_OF_REQUEST_CLASSES_ON_CALENDAR).next
    end

    css_class = "app#{class_number}"
    div_content = request_calendar_content(req).html_safe
    title_content = content_tag(:div, request_calendar_content(req, for_title: true),
                                      {class: "#{css_class} request calendar unathenticatedCalendar",
                                        style: 'font-size:11px;'},
                                      false)
    content_tag(:div, div_content, 
                      {title: title_content.gsub("\"", "'"),
                       class: "#{css_class} request"},
                      false)
  end

  def request_calendar_content(req, opts = {})
    for_title = opts.fetch(:for_title, false)
    should_truncate = !for_title

    content = for_title ? "#{req.number}<br/>".html_safe : ''.html_safe
    package_content_tags = req.package_content_tags

    content << "<strong>#{req.name.blank? ? '-'.html_safe : h(req.name)}</strong><br/>".html_safe

    # cp => calendar_preferences
    cp = user_signed_in? ? current_user.get_calendar_preferences : GlobalSettings[:calendar_preferences]


    if cp.include?('business_process_name')
      unless req.business_process.nil?
        bg_color = req.business_process.label_color rescue ''
        content << content_tag(:div, req.business_process.name, {style: "background:#{bg_color};"}, false)
        content << '<br/>'.html_safe
      end
    end

    content << "#{ensure_string(req.owner_name, '-')}<br />".html_safe if cp.include?('owner_name')

    if cp.include?('release_name')
      content << "#{req.release.nil? || req.release.blank? ? '-'.html_safe : h(conditional_truncate(req.release_name, should_truncate))}<br />".html_safe
    end

    if cp.include?('app_name')
      content << (ensure_space(req.app_name.to_sentence) + '<br />'.html_safe)
    end

    if cp.include?('environment_name')
      content << "#{req.environment.nil? || req.environment.default? ? '-'.html_safe : h(conditional_truncate(req.environment_label, should_truncate))}<br />".html_safe
    end

    if cp.include?('package_content_tags')
      content << "#{ensure_string(conditional_truncate(package_content_tags, should_truncate), '-')}<br />".html_safe
    end

   #Yes, 'lifecyle_name' minus the 'C' and not plan_name
    if cp.include?('lifecyle_name')
      content << "#{ensure_string(conditional_truncate(req.try(:plan).try(:name), should_truncate), '-')}<br />".html_safe
    end

    if cp.include?('project_name')
      # Project name should be associate with request
      #content << "#{ensure_string(conditional_truncate(req.project_name, should_truncate), '-')}<br />"
      content << "#{ensure_string(conditional_truncate(req.activity ?  req.activity.name : '' , should_truncate), '-')}<br />".html_safe

    end

    if cp.include?('associated_servers')
      content << "#{ensure_string(conditional_truncate(req.associated_servers, should_truncate), '-')}<br />".html_safe
    end

    if cp.include?('rescheduled')
      content << "Rescheduled: #{req.rescheduled? ? 'Yes' : 'No'}<br />".html_safe
    end

    if cp.include?('estimate')
      content << "Estimate: #{ensure_space h(request_duration(req))}<br />".html_safe
    end

    if cp.include?('team')
      teams = req.apps.map(&:teams)
      team_names = teams.map(&:name).to_sentence
      content << "#{ensure_string(conditional_truncate(team_names , should_truncate), '-')}<br />".html_safe
    end

    visible = (current_user && req.is_visible?(current_user)) ? true : false
    content = link_to_if (visible && can?(:inspect, req)), content, request_path(req), style: 'border-bottom:none;'
    request_id = content_tag(:span, req.number, {class: 'request_id', style: ' padding-bottom:0px;padding-top:0px;border-bottom:none;'}, false)
    unscheduled = req.scheduled_at.present? ? '' : 'unscheduled'

    if cp.include?('aasm.current_state')
      content << ("<div class=\"#{req.aasm.current_state}RequestStep #{unscheduled} request_step state\">" + request_id + h("#{req.aasm.current_state}") + '</div>').html_safe
    else
      content << "<div>#{request_id}</div>".html_safe
    end

    if req.calendar_ready?
      content << "<div style='padding-top:1px;clear:both;'>#{req.humanized_calendar_time_source}: #{req.calendar_order_time.to_s(:time_only)}</div>".html_safe
    end

    content
  end

  def style_for_process(business_process)
    business_process.label_color
  end

  def conditional_truncate(val, should_truncate)
    should_truncate ? truncate(val, length: 20) : val
  end

end

