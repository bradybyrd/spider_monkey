################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class FusionChart < ActiveRecord::Base

  def self.columns
    @columns ||= []
  end

  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  concerned_with :completed_report
  concerned_with :problem_trend
  concerned_with :time_of_problem
  concerned_with :time_to_complete
  concerned_with :volume_report
  concerned_with :report_csv
  concerned_with :release_calendar
  concerned_with :environment_calendar

  attr_accessor :period, :filters, :start_date, :end_date

  Types = %w(volume-report problem-trend-report time-of-problem completed-report time-to-complete release-calendar environment-calendar events-calendar)
  # Colors = %w(FF8C00 228B22 DAA520 9ACD32 4682B4 9370D8 4169E1 000080 DC143C FF4500 8B4513 40E0D0 FFFF00) #DarkOrange, ForestGreen, GoldenRod, YellowGreen, SteelBlue, MediumPurple, RoyalBlue, Navy, Crimson, OrangeRed, SaddleBrown, Turquoise, Yellow
  Colors = %w(87759D DBDB4C 7A9A9B E0897F 4C96C0 EFDA51 98AD68 EB9D60)

  def initialize(options = {})
    self.period     = options[:period]
    self.filters    = options[:filters]
    self.start_date = options[:start_date]
    self.end_date   = options[:end_date]
  end

  def finder_opts(app_id=nil)
    conditions = {}
    conditions.update environment_id: filters[:environment_id] if filters && filters[:environment_id].present?
    conditions.update business_process_id: filters[:business_process_id] if filters && filters[:business_process_id].present?
    conditions.update release_id: filters[:release_id] if filters && filters[:release_id].present?
    conditions.update 'steps.work_task_id' => filters[:work_task_id] if (filters && filters[:work_task_id])
    conditions.update 'steps.component_id' => filters[:component_id] if (filters && filters[:component_id])
    conditions.update 'steps.owner_id' => filters[:owner_id] if (filters && filters[:owner_id]) unless @do_not_filter_by_step
    conditions.update aasm_state: filters[:aasm_state] if filters && filters[:aasm_state].present?
    conditions.update 'apps_requests.app_id' => app_id || filters[:app_id] if app_id || (filters && filters[:app_id])
    conditions
  end

  def finder_opts_for_calendar(app_id=nil, plan_id=nil, env_id=nil)
    conditions = {}
    conditions.update environment_id: filters[:environment_id] if filters && filters[:environment_id].present?
    conditions.update plan_id: filters[:plan_id] if filters && filters[:plan_id].present?
    conditions.update app_id: app_id || filters[:app_id] if app_id || (filters && filters[:app_id].present?)

    conditions
  end

  def conditions_for_plans
    conditions = {}
    conditions.update id: filters[:plan_id] if filters && filters[:plan_id].present?
    conditions.update aasm_state: filters[:aasm_state] if (filters && filters[:aasm_state].present? && filters[:aasm_state]!= 'Deleted')

    conditions
  end

  def exclude_archived_if_without_filter
    if filters && filters[:aasm_state].present? && !filters[:aasm_state].include?('archived')
      conds = 'plans.aasm_state != ?', 'archived'
    elsif filters && filters[:aasm_state].blank?
      conds = 'plans.aasm_state != ?', 'archived'
    end
  end

  def apps_in_report
    @apps = App.id_equals(filters[:app_id])
  end
  alias :apps :apps_in_report

  def refectored_requests(all_req_ids, state, group_by=nil)

    @requests = Request.inner_apps_requests.accessible_to_user(User.current_user)
    if @requests.present?
      @requests = @requests.in_state(state)

      beginning_of_calendar = (filters.present? && filters[:beginning_of_calendar].present?) ? filters[:beginning_of_calendar] : DateTime.now-180
      end_of_calendar = (filters.present? && filters[:end_of_calendar].present?) ? filters[:end_of_calendar] : DateTime.now

      @requests = @requests.between_dates(beginning_of_calendar, end_of_calendar)
      select = 'requests.id, apps_requests.app_id AS app_id'
      select += ", #{@columns_to_select}" if @columns_to_select
      join = @join if @join
      finder_opts.update('requests.id' => all_req_ids)
      @requests = @requests.where(finder_opts).select(select).joins(join)
      @requests = @requests.group_by(&:"#{group_by}") if group_by.present?
      @requests
    end
  end

  def requests(requests_from_get_data, state, group_by=nil)
    @requests = requests_from_get_data.inner_apps_requests

    if @requests.present?
      @requests = @requests.in_state(state)

      beginning_of_calendar = (filters.present? && filters[:beginning_of_calendar].present?) ? filters[:beginning_of_calendar] : DateTime.now-180
      end_of_calendar = (filters.present? && filters[:end_of_calendar].present?) ? filters[:end_of_calendar] : DateTime.now

      @requests = @requests.between_dates(beginning_of_calendar, end_of_calendar)
      select = 'requests.id, apps_requests.app_id AS app_id'
      select += ", #{@columns_to_select}" if @columns_to_select
      join = @join if @join
      @requests = @requests.where(finder_opts).select(select).joins(join)
      @requests = @requests.group_by(&:"#{group_by}") if group_by.present?
      @requests
    end

  end

end
