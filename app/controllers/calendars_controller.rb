################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

class CalendarsController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token, only: [:upcoming_requests, :month, :rolling, :day, :week]
  before_filter :preserve_filters
  before_filter :format_date
  before_filter :switch_mode
  before_filter :get_recent_activities, :get_current_users, only: [:month, :day, :week, :rolling]

  def month
    authorize_calendar!
    date_of_month
    @calendar = Calendar::Month.new(params[:beginning_of_calendar])
    draw_calendar
  end

  def day
    authorize_calendar!
    date_of_month
    @calendar = Calendar::Day.new(params[:beginning_of_calendar])
    draw_calendar
  end

  def week
    authorize_calendar!
    date_of_month
    @calendar = Calendar::Week.new(params[:beginning_of_calendar])
    draw_calendar
  end

  def rolling
    authorize_calendar!
    date_of_month
    @calendar = Calendar::Rolling.new(params[:beginning_of_calendar])
    draw_calendar
  end

  def upcoming_requests # Printed report of up-coming requests - Current Week + Next Two Weeks
    authorize! :view_calendar, Request.new
    params.merge!({beginning_of_calendar: Date.today}) if (not user_signed_in? or not params[:beginning_of_calendar].present?)
    date_of_month if params[:beginning_of_calendar].present?
    @calendar = Calendar::Week.new(params[:beginning_of_calendar])
    @one_week_ahead = Calendar::Week.new(next_week_start(7))
    @two_week_ahead = Calendar::Week.new(next_week_start(14))
    @beginning_of_calendar = params[:beginning_of_calendar]
    @list_view = true
    @page_path = '/calendars/upcoming-requests' if params[:page_path].present?
    draw_calendar
  end

  def reset_filters_hash!
    (streamstep_filters + %w(outbound_requests inbound_requests)).each {
      |s| session['calendar_session'].delete_if {|key, _| key.to_s == s.to_s }
    }
  end

  private

  def switch_mode
    if params[:display_format].present? && params[:display_format] != params[:action]
      redirect_to(params.except(:display_format, :filters).
                         merge(action: params[:display_format],
                               for_dashboard: params[:for_dashboard]))
      return
    end
  end

  def draw_calendar
    @split_date_by = '/'
    Time.zone = params[:time_zone] unless params[:time_zone].blank?
    @filters.update(participated_in_by: params[:for_dashboard] ? current_user.id : nil) if user_signed_in?
    @calendar.filters = @filters
    @calendar.plan = Plan.find(params[:plan_id]) unless params[:plan_id].blank?
    if defined?(@one_week_ahead) && defined?(@two_week_ahead)
      @one_week_ahead.filters, @two_week_ahead.filters = @calendar.filters, @calendar.filters
      if @calendar.plan
        @one_week_ahead.plan, @two_week_ahead.plan = @calendar.plan, @calendar.plan
      end
    end

    @for_dashboard = params[:for_dashboard] if params[:for_dashboard]
    @params = params
    if request.xhr?
      render partial: 'dashboard/self_services/calendar.html.erb'
    else
      respond_to do |format|
        format.html do
          if @calendar.plan
            @plan = @calendar.plan
            plan_release_details
            render template: 'plans/calendar', layout: cal_layout
          elsif params[:for_dashboard] && user_signed_in?
            dashboard_setup
            @page_path = @list_view.blank? ? nil : '/calendars/upcoming-requests'
            get_data(!user_signed_in?)
            my_applications
            render template: 'dashboard/self_services'
          else
            render template: 'calendars/calendar', layout: cal_layout
          end
        end
        format.pdf do
          render pdf: "#{params[:pdf_type]}_#{Time.now.strftime('%m-%d-%Y_%H_%M_%S')}", template: 'calendars/pdf', handlers: [:erb], formats: [:html],
                 layout: 'calendar', show_as_html: params[:export] ? true : false
        end
        format.csv do
          send_data Request.generate_csv_report(@calendar.first_day, @two_week_ahead.last_day, @calendar), type: 'text/csv', filename: "#{@calendar.first_day}-#{@two_week_ahead.last_day}.csv"
        end
      end
    end
  end

  def cal_layout
    user_signed_in? ? 'application' : 'calendar'
  end

  def preserve_filters
    # Requests should not be filtered by `participated_in_by` on Plan page
    params[:filters][:participated_in_by] = nil if params[:filters].present? && params[:plan_id].present?
    @calender_page = true
    session['calendar_session'] ||= HashWithIndifferentAccess.new
    unless params[:filters].nil_or_empty? || params[:dont_update_session]
      sanitized_params = params[:filters]
      sanitized_params.each { |k, v| sanitized_params[k] = ERB::Util.html_escape(v) if v.is_a?(String) }
      session['calendar_session'].replace( sanitized_params )
    end
    reset_filters_hash! if params[:clear_filter]
    session[:calendar] ||= HashWithIndifferentAccess.new
    session[:calendar].update(display_format: params[:action],
                              beginning_of_calendar: params[:beginning_of_calendar]) unless params[:action] == 'upcoming_requests'

    @filters = session['calendar_session']
  end


  def next_week_start(weeks)
    (params[:beginning_of_calendar].to_date + weeks.days).to_s
  end

  def get_recent_activities
    @recent_activities = RecentActivity.order('recent_activities.id desc').limit(3)
## Temporarily reverting the fix for defect DE68835
# Correct fix is below. However, we will need to modify the query to fix it so that
# a user can see the activity for the request he himself created
#
#    ra = current_user.related_recent_activity
#    @recent_activities = if ra.kind_of?(Array)
#      ra.first(3)
#    else
#      ra.all(:limit => 3)
#    end
  end

  def date_of_month
    if params[:date_start].present?
      calculate_date(params[:date_start])
      params[:beginning_of_calendar] = @date
    else
      @date = params[:beginning_of_calendar].to_date if params[:beginning_of_calendar].present?
    end
  end

  def calculate_date(month_no)
    # Date.parse function in ruby 1.9 have different implementation as compared to Date.parse function in ruby-1.8
    # Reference article: http://stackoverflow.com/questions/5372464/ruby-1-87-vs-1-92-date-parse
    #date = Date.parse "#{month_no}/01/#{Date.today.year}"
    date = Date.strptime "#{month_no}/01/#{Date.today.year}", '%m/%d/%Y'
    @date = date
  end

  def format_date
    if params[:beginning_of_calendar].present? && GlobalSettings[:default_date_format].include?('-')
      params[:beginning_of_calendar] = params[:beginning_of_calendar].to_date.strftime(GlobalSettings[:default_date_format])
    elsif params[:beginning_of_calendar].present? && params[:beginning_of_calendar].include?('-')
      params[:beginning_of_calendar] = params[:beginning_of_calendar].gsub('-', '/')
    end
  end

  def get_current_users
    @request_dashboard ||= {}
    @request_dashboard[:current_users] = User.get_current_users rescue []
  end

  def requests_tab?
    !dashboard_tab?
  end

  def dashboard_tab?
    params['for_dashboard']
  end

  def authorize_calendar!
    authorize! :view_calendar, Request.new if requests_tab?
    authorize! :view, :dashboard_calendar if dashboard_tab?
  end
end
