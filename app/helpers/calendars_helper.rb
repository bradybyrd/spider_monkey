################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

module CalendarsHelper

  def previous_calendar_path
    url_for(@calendar.filters.merge(plan_id: @calendar.plan.try(:id),
                                    beginning_of_calendar: custome_previous(@calendar),
                                    for_dashboard: params[:for_dashboard],
                                    page_path: params[:page_path].present? ? params[:page_path] : nil))
  end

  def next_calendar_path
    url_for(@calendar.filters.merge(beginning_of_calendar: @calendar.next,
                                    for_dashboard: params[:for_dashboard],
                                    plan_id: @calendar.plan.try(:id),
                                    page_path: params[:page_path].present? ? params[:page_path] : nil))
  end

  def this_calendar_url
    url_for(@calendar.filters.merge!(used_filters: @params[:used_filters]).except(:for_dashboard).merge(
        action: session[:calendar][:display_format],
        beginning_of_calendar: (@date || nil),
        plan_id: @calendar.plan.try(:id),
        filters: @filters.except(:participated_in_by)).merge(for_dashboard: nil))
  end

  def requests_for_coming_weeks_url(dont_update_session = false)
    params.merge!(dont_update_session: true) if dont_update_session
    upcoming_requests_path(params: params.except(:for_dashboard, :display_format).merge(
        beginning_of_calendar: nil,
        action: 'upcoming_requests',
        filters: @filters.except(:participated_in_by),
        page_path: params[:page_path].present? ? params[:page_path] : nil)
    )
  end

  def first_day_of_week
    (Time.now - (Date.today.wday).days).to_date.to_s
  end

  def duration_of_week(week) # Returns 'April 4th 2010 - April 10th 2010'
    "#{day_to_date_string(week.days.first)} - #{day_to_date_string(week.days.last)}"
  end

  def day_to_date_string(day) # Returns 'April 4th 2010'
    "#{day.strftime('%B')} #{ordinalize(day.strftime('%d').to_i)} #{day.strftime('%Y')}"
  end

  def my_calendar_path
    if session[:calendar].present?
      url_for(controller: '/calendars',
              for_dashboard: true,
              action: session[:calendar][:display_format],
              beginning_of_calendar: session[:calendar][:beginning_of_calendar])
    else
      calendar_dashboard_months_path
    end
  end

  def my_all_calendar_path(args={})
    if session[:calendar].present?
      url_for(controller: '/calendars',
              action: session[:calendar][:display_format],
              beginning_of_calendar: (session[:calendar][:beginning_of_calendar] || @date),
              plan_id: args[:plan_id])
    else
      calendar_months_path(plan_id: args[:plan_id])
    end
  end

  def custome_previous(obj)
    if params[:action] == 'week' || params[:action] == 'rolling' || params[:action] == 'upcoming_requests'
      obj.first_day - 1.week
    else
      obj.class.new(obj.first_day - 1)
    end
  end

  def deliverable_calendar_header
    header_string = ''
    header_string << "#{GlobalSettings[:company_name]}: " if GlobalSettings[:company_name]
    header_string << 'BMC Release Process Management Report'
    content_tag(:h1, header_string)
  end

end

