################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

module ReportsHelper
  def report_period_options
    options_for_select(['last week', 'last 2 weeks', 'last month', 'last 3 months', 'last year'])
  end

  def draw_gantt(gantt)
    draw_activity_roadmap gantt
  end

  def draw_activity_roadmap(gantt)
    gantt_javascript(gantt)

    contents = ''
    before = ''

    if gantt.blank?
      contents << content_tag(:h2, 'Please select an activity to the right')
      return contents
    end

    before << content_tag(:h1, gantt.activity.try(:name))

    before << year_links

    before + content_tag(:div, contents, class: "gantt gantt_#{gantt.object_id}",
                         style: 'min-height: 100px; clear:both')
  end

  def year_links
    if @year
      links = ''
      links << link_to_function("&laquo; #{@year - 1}", '', class: 'change_year', rel: @year - 1, style: 'float:left;margin-left: 100px')
      links << link_to_function("#{@year + 1} &raquo;", '', class: 'change_year', rel: @year + 1, style: 'float:right;')
      links << content_tag(:div, @year, style: 'font-weight:bold;text-align:center;')
      content_tag(:div, links, style: 'width: 700px;margin-left:-100px;')
    else
      ''
    end
  end

  def gantt_javascript(gantt)
    content_for :head do
      javascript_tag gantt
    end
  end

  def filter_x_axis(selected_options, key)
    if key == 'precision'
      selected_options[key.to_sym] == nil || selected_options[key.to_sym] == '' ? 'Month' : selected_options[key.to_sym].capitalize
    else
      selected_options[key.to_sym] == nil || selected_options[key.to_sym] == '' ? 'Part of' : selected_options[key.to_sym].gsub('-',' ').capitalize
    end
  end

  def load_reports_js(report_type)
    case report_type
    when 'volume_report'
      javascript_include_tag '/FusionCharts/FusionCharts', '/FusionCharts/FusionChartsExportComponent'
    when 'problem_trend_report'
      javascript_include_tag '/FusionCharts/FusionCharts', '/FusionCharts/FusionChartsExportComponent'
    when 'time_of_problem'
      javascript_include_tag 'PowerCharts/Charts/FusionCharts', 'PowerCharts/Charts/FusionChartsExportComponent'
    when 'time_to_complete'
      javascript_include_tag 'PowerCharts/Charts/FusionCharts', 'PowerCharts/Charts/FusionChartsExportComponent'  
    end
  end

  def report_title(report_type)
    if report_type == 'release_calendar'
      'Release Calendar Report'
    elsif report_type == 'environment_calendar'
      'Environment Calendar Report'
    else
      'Process Reports'
    end
  end

  def select_group_on(selection)
    if selection && selection[:group_on] && !selection[:group_on].empty?
      selection[:group_on]
    else
      'part of'
    end
  end

  def select_precision(selection)
    if selection && selection[:precision] && !selection[:precision].empty?
      selection[:precision]
    else
      'month'
    end
  end

  def selected_date(date)
    date.blank? ? nil : date.strftime(GlobalSettings.first.default_date_format)
  end

  def can_access_report?(report_type)
    report_type == 'volume_report' && can?(:view, :volume_report) ||
    report_type == 'time_to_complete' && can?(:view, :time_to_complete_report) ||
    report_type == 'problem_trend_report' && can?(:view, :problem_trend_report) ||
    report_type == 'time_of_problem' && can?(:view, :time_to_problem_report) ||
    report_type == 'release_calendar' && can?(:view, :release_calendar) ||
    report_type == 'environment_calendar' && can?(:view, :environment_calendar) ||
    report_type == 'deployment_windows_calendar' && can?(:view, :deployment_windows_calendar)
  end

  def reports_selected_tab(report_type)
    case report_type
    when 'release_calendar', 'environment_calendar', 'deployment_windows_calendar'
      'calendars'
    else
      'process'
    end
  end

  def reports_tab_path
    can?(:view, :volume_report) ? reports_path(report_type: 'volume_report') : reports_path
  end

end
