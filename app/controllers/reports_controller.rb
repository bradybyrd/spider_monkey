################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ReportsController < ApplicationController
  layout 'application', :except => [:environment_options]

  around_filter :render_index, only: [ :release_calendar,
                                       :deployment_windows_calendar,
                                       :environment_calendar ]
  before_filter :prepare_calendar, only: [ :release_calendar,
                                           :deployment_windows_calendar,
                                           :environment_calendar ]
  before_filter :clear_filter, only: [ :release_calendar,
                                       :deployment_windows_calendar,
                                       :environment_calendar ]

  FusionChart::Types.each do |report|
    define_method report.underscore do
      if params[:report] == report.underscore
        redirect_to(reports_url(:report_type => report.underscore,
                                :filters => params[:filters]))
      end
    end
  end

  def release_calendar
    if @width
      @release_calendar, start_date, finish_date, _ =
        @fusionchart.release_calendar @selected_options,
                                      params[:p],
                                      session[:rel_start],
                                      session[:rel_end],
                                      session[:scale_unit],
                                      @beginning_of_calendar,
                                      @end_of_calendar,
                                      @width
      session[:rel_start], session[:rel_end] = [ start_date, finish_date ]
      flash[:notice] = 'No matching records' if @release_calendar.empty?
    end

    if request.xhr?
      render :partial => 'release_calendar',
             :locals => { :width => @width }# if @release_calendar.present?
    else
      render action: :index
    end
  end

  def environment_calendar
    if @width
      @environment_calendar =
        @fusionchart.environment_calendar @selected_options,
                                          params[:p],
                                          session[:env_start],
                                          session[:env_end],
                                          session[:scale_unit],
                                          @beginning_of_calendar,
                                          @end_of_calendar,
                                          @width
      flash[:notice] = 'No matching records' if @environment_calendar.empty?
    end

    if request.xhr?
      render :partial => 'environment_calendar',
             :locals => { :environment_calendar => @environment_calendar,
                          :width => @width } if @environment_calendar
    else
      render action: :index
    end
  end

  def deployment_windows_calendar
    if @width
      session[:events_start], session[:events_finish] =
        @fusionchart.get_time_limits params[:p],
                                     session[:events_start],
                                     session[:events_finish],
                                     session[:scale_unit],
                                     @beginning_of_calendar,
                                     @end_of_calendar,
                                     @width

      @environments = current_user.environments

      flash[:notice] = 'No matching records' if @environments.empty?
      @presenter = EventsCalendarPresenter::Base.new @environments,
                                                     session[:scale_unit],
                                                     session[:events_start],
                                                     session[:events_finish],
                                                     session[:deployment_windows_calendar][:filters]
    end

    if request.xhr?
      render :partial => 'deployment_windows_calendar',
             :locals => { :environments => @environments,
                          :width => @width }
    else
      render action: :index
    end
  end

  def index
    authorize! :view, :reports_tab
    report_type      = params[:report_type]
    if report_type.nil?
      render_blank_page
    else
      authorize! :view, report_ability_subject(report_type)
      handle_appropriate_report
    end
  end

  def set_date
    start_date = params[:filters][:beginning_of_calendar]
    end_date = params[:filters][:end_of_calendar]
    params[:filters][:beginning_of_calendar] = Date.generate_from(start_date) if start_date.present?
    params[:filters][:end_of_calendar] = Date.generate_from(end_date) if end_date.present?
    params[:filters]
  end

  def set_filter_session
    if params[:reset_filter_session] == 'true'
      FusionChart::Types.each do |report|
        session[report.underscore.to_sym] = {}
        session[:scale_unit] = {}
      end
    else
      if @report_type != "release_calendar" && @report_type != "environment_calendar" && @report_type != 'deployment_windows_calendar'

        unless params[:commit] == "Clear Filter"
          if params[:filters]["beginning_of_calendar"].blank? and params[:filters]["end_of_calendar"].blank?
             if session[@report_type.underscore.to_sym][:filters] && session[@report_type.underscore.to_sym][:filters]["beginning_of_calendar"].present?
               params[:filters]["beginning_of_calendar"] = session[@report_type.underscore.to_sym][:filters]["beginning_of_calendar"]
             else
               params[:filters].delete("beginning_of_calendar")
             end

             if session[@report_type.underscore.to_sym][:filters] && session[@report_type.underscore.to_sym][:filters]["end_of_calendar"].present?
               params[:filters]["end_of_calendar"] = session[@report_type.underscore.to_sym][:filters]["end_of_calendar"]
             else
               params[:filters].delete("end_of_calendar")
             end
          end
        end

      end
      session[@report_type.underscore.to_sym] = { :filters => params[:filters] ||{} }
      session[:scale_unit] = params[:scale_unit]
    end
    # redirect_to(reports_url(:report_type => "#{params[:report_type].underscore}"))
  end


  def environment_options
    @app = App.find_by_id(params[:app_id] || params[:criterion_id])
    render :text => options_from_model_association(@app, :environments)
  end

  def requests
    @requests = Request.id_equals(params[:request_ids])
    render :partial => "requests_list"
  end

  def toggle_filter
    if params[:open_filter] == 'true'
      session[:open_report_filter] = true
    else
      session[:open_report_filter] = false
    end
    render :nothing => true
  end

  def generate_csv
    respond_to do |format|
      format.csv do
        request_ids = params[:request_ids].split
        send_data FusionChart.generate_csv_report(request_ids), :type => 'text/csv', :filename => filename(request_ids)
      end
    end
  end

  def set_resolution_session
    @width = params[:screen_width].to_i
    render :text => @width
  end

protected

  def filename(request_ids)
    "#{request_ids.count} requests in #{Request.find(request_ids.first).aasm_state} state.csv"
  end
  # This method is not required now, but will be used when we add filters in all the new reports
  def initialize_fusion_chart(report_type)
    @fusionchart = FusionChart.new(:period => session[report_type][:period],
                                   :filters => session[report_type][:filters],
                                   :start_date => session[report_type][:start_date],
                                   :end_date => session[report_type][:end_date])
  end

  def set_calender_session(report_type)
    report_type = report_type.underscore.to_sym
    @beginning_of_calendar = session[report_type][:filters][:beginning_of_calendar] if session[report_type]
    @end_of_calendar = session[report_type][:filters][:end_of_calendar] if session[report_type]
  end

private

  def prepare_calendar
    @width = params[:width].present? ?
      params[:width].to_i :
     (params[:screen_resolution].present? ? params[:screen_resolution].to_i :
                                            nil)
    params[:filters] = set_date
    @report_type = params[:action]
    set_filter_session if params[:filters]

    @open_filter = session[:open_report_filter]
    set_calender_session @report_type
    @selected_options = session[  @report_type.underscore.to_sym  ][:filters] || {}
    initialize_fusion_chart(@report_type.to_sym)
  end

  FILTER_DATES_KEYS = { 'release_calendar' => [:rel_start, :rel_end],
                        'environment_calendar' => [],
                        'deployment_windows_calendar' => [:events_start, :events_finish] }

  def clear_filter
    keys = FILTER_DATES_KEYS[params[:action]]

    if keys.present? && params[:commit] == 'Clear Filter'
      session[ keys.first ] = false
      session[ keys.second ] = false
    end
  end

  def render_index
    if params[:p].present? || params[:r].present? || 'Filter' == params[:commit]
      yield
    else
      if params[:q].blank?
        respond_to do |format|
          # before_filter runs after around_filter. If `yield' in
          # around_filter doesn't call then no before_filter triggers. So we
          # need to call `prepare_calendar' manually.
          prepare_calendar
          format.html { render :index }
        end
      else
        # ?
      end
    end
  end

  def get_width
    if params[:width].present?
      params[:width].to_i
    else
      params[:screen_resolution].present? ? params[:screen_resolution].to_i : nil
    end
  end

  def set_report_type_variable
    if @width
      if params[:report_type] == 'release_calendar'
        @instance_variable = instance_variable_set "@#{params[:report_type]}",
                                                   @fusionchart.send(params[:report_type],
                                                                     session[params[:report_type].underscore.to_sym][:filters],
                                                                     params[:p],
                                                                     session[:rel_start],
                                                                     session[:rel_end],
                                                                     session[:scale_unit],
                                                                     @beginning_of_calendar,
                                                                     @end_of_calendar, @width)[FusionChart::CALENDAR_DATA_INDEX]
      elsif params[:report_type] =='environment_calendar'
        @instance_variable = instance_variable_set "@#{params[:report_type]}",
                                                   @fusionchart.send(params[:report_type],
                                                                     session[params[:report_type].underscore.to_sym][:filters],
                                                                     params[:p],
                                                                     session[:env_start],
                                                                     session[:env_end],
                                                                     session[:scale_unit],
                                                                     @beginning_of_calendar,
                                                                     @end_of_calendar, @width)
      else

        @requests = current_user.requests(true).exclude_templates.functional
        @requests = @requests.in_progress
        @instance_variable = instance_variable_set "@#{params[:report_type]}",
                                                   @fusionchart.send(params[:report_type],
                                                                     session[params[:report_type].underscore.to_sym][:filters],
                                                                     @requests)
      end
      if @instance_variable.empty? || (params[:report_type] == 'volume_report' && @instance_variable.first['total_request']==0)
        flash[:notice] = 'No matching records'
      end
    end
  end

  def clear_report_types_filters
    if @report_type == 'release_calendar'
      session[:rel_start] = false
      session[:rel_end]   = false
    elsif @report_type == 'environment_calendar'
      session[:env_start] = false
      session[:env_end]   = false
    end
  end

  def handle_appropriate_report
    process_report_data if params[:report_type].present?
    render_appropriate_report || render_blank_page
  end

  def render_appropriate_report
    if params[:p].present? || params[:r].present?
      if params[:report_type] == 'release_calendar'
        render partial: 'release_calendar',
               locals: {release_calendar: @release_calendar, width: @width} if @release_calendar
      else
        render partial: 'environment_calendar',
               locals: {environment_calendar: @environment_calendar, width: @width} if @environment_calendar
      end
    else
      if params[:q].present?
        if @report_type == 'volume_report'
          authorize! :view, :volume_report
          render :partial => 'fusioncharts/process_volume',
                 :locals => { :volume_report => @volume_report,
                              :width => @width } if @volume_report
        elsif @report_type == "time_to_complete"
          authorize! :view, :time_to_complete_report
          render :partial => 'fusioncharts/time_to_complete',
                 :locals => { :time_to_complete => @time_to_complete,
                              :width => @width } if @time_to_complete
        elsif @report_type == 'problem_trend_report'
          authorize! :view, :problem_trend_report
          render :partial => 'fusioncharts/problem_trend',
                 :locals => { :problem_trend_report => @problem_trend_report,
                              :selected_options => @selected_options,
                              :width => @width } if @problem_trend_report
        elsif @report_type == 'time_of_problem'
          authorize! :view, :time_to_problem_report
          render :partial => 'fusioncharts/time_of_problem',
                 :locals => { :time_of_problem=> @time_of_problem,
                              :selected_options => @selected_options,
                              :width => @width } if @time_of_problem
        end
      end
    end
  end

  def render_blank_page
    respond_to do |format|
      format.html
    end
  end

  def process_report_data
    @width            = get_width

    params[:filters]  = set_date
    @report_type      = params[:report_type]
    set_filter_session if params[:filters]

    clear_report_types_filters if params[:commit] == 'Clear Filter'

    @open_filter      = session[:open_report_filter]
    set_calender_session @report_type
    @selected_options = session[@report_type.underscore.to_sym][:filters] || {}

    initialize_fusion_chart(@report_type.to_sym)

    set_report_type_variable
  end

  def report_ability_subject(report_type)
    case report_type
      when 'time_to_complete' then :time_to_complete_report
      when 'time_of_problem' then :time_to_problem_report
      else report_type.to_sym
    end
  end
end
