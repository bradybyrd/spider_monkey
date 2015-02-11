class FusionChart
  SECONDS_IN_DAY = 60 * 60 * 24
  SECONDS_IN_WEEK = 7 * SECONDS_IN_DAY
  CALENDAR_DATA_INDEX = 0
  MAX_DAYS_TO_SHOW = 7

  def release_calendar(filters,
                       p_param = nil,
                       sdate = nil,
                       edate = nil,
                       unit = nil,
                       beginning_of_calendar = nil,
                       end_of_calendar = nil,
                       width = nil)

    startd, endd = get_time_limits p_param,
                                   sdate,
                                   edate,
                                   unit,
                                   beginning_of_calendar,
                                   end_of_calendar,
                                   width
    plans = Plan.entitled(User.current_user)
                .includes(plan_env_app_dates: :environment)
                .where('plans.aasm_state != ?', 'deleted')
                .starting_in(startd, endd)
                .filter(conditions_for_plans, exclude_archived_if_without_filter)
                .filter_with_relations(finder_opts_for_calendar)
                .order('plans.name')
                .order('plan_env_app_dates.planned_start')

    calendar_data = wrap_with_hash_to_display plans
    calendar_data['p'] = p_param if p_param.present?

    [ calendar_data, startd, endd, plans ]
  end

  def wrap_with_hash_to_display(plans)
    Hash[
      plans.map do |plan|
        [
          plan,
          plan.plan_env_app_dates.map do |plan_env_app_date|
            [
              plan_env_app_date.planned_start,
              plan_env_app_date.planned_complete,
              plan_env_app_date.environment,
              plan.plan_env_app_dates.last.planned_complete,
              plan_env_app_date.app_id,
              plan.plan_env_app_dates.scoped.uniq.pluck('plan_env_app_dates.environment_id')
            ]
          end + [plan.plan_env_app_dates.scoped.uniq.pluck('plan_env_app_dates.environment_id')]
        ]
      end
    ]
  end

  def get_time_limits(p_param = nil,
                      sdate = nil,
                      edate = nil,
                      unit = nil,
                      beginning_of_calendar = nil,
                      end_of_calendar = nil,
                      width = nil)
    screen_width = width.blank? ? 1024 : width
    usable_width = screen_width

    month_def_width = 200
    day_def_width = 75
    week_def_width = 200

    no_of_months_to_show = (usable_width / month_def_width).floor
    no_of_days_to_show = [ (usable_width / day_def_width).floor, MAX_DAYS_TO_SHOW ].min
    no_of_weeks_to_show = (usable_width / week_def_width).floor

    if sdate.blank? and edate.blank?
      first_date_last_month = (Time.now).at_end_of_month
      first_date_begin_month = first_date_last_month.months_ago(no_of_months_to_show - 1)
                                                    .at_beginning_of_month
    else
      if unit == "m"
        is_datefilter_set = false
        if beginning_of_calendar.present? and end_of_calendar.blank?
          first_date_begin_month = p_param.blank? ?
            Date.generate_from(beginning_of_calendar).to_time.at_beginning_of_month :
            sdate.at_beginning_of_month
          first_date_last_month = first_date_begin_month.months_since(no_of_months_to_show - 1)
                                                        .at_end_of_month
          is_datefilter_set = true
        elsif beginning_of_calendar.blank? and end_of_calendar.present?
          first_date_last_month = p_param.blank? ?
            Date.generate_from(end_of_calendar).to_time.at_end_of_month :
            edate.at_end_of_month
          first_date_begin_month = first_date_last_month.months_ago(no_of_months_to_show - 1)
                                                        .at_beginning_of_month
          is_datefilter_set = true
        elsif beginning_of_calendar.present? and end_of_calendar.present?
          if beginning_of_calendar.to_date > sdate.at_beginning_of_month.to_date &&
             end_of_calendar.to_date < edate.at_end_of_month.to_date
            first_date_begin_month = Date.generate_from(beginning_of_calendar).to_time
            first_date_last_month = Date.generate_from(end_of_calendar).to_time
          else
            first_date_begin_month = p_param.blank? ?
              Date.generate_from(beginning_of_calendar).to_time.at_beginning_of_month :
              sdate.at_beginning_of_month
            date1 = Date.generate_from(end_of_calendar).to_time
            date2 = first_date_begin_month.months_since(no_of_months_to_show - 1).at_end_of_month
            first_date_last_month = date1 < date2 ? date1 : date2
          end
          is_datefilter_set = true
        elsif beginning_of_calendar.blank? and end_of_calendar.blank?
          first_date_begin_month = sdate.at_beginning_of_month
          first_date_last_month = first_date_begin_month.months_since(no_of_months_to_show - 1)
                                                        .at_end_of_month
        end
      elsif unit == "d"
        is_datefilter_set = false
        if beginning_of_calendar.present? and end_of_calendar.blank?
          first_date_begin_month = p_param.blank? ? Date.generate_from(beginning_of_calendar).to_time :
                                              sdate
          first_date_last_month = first_date_begin_month + no_of_days_to_show * SECONDS_IN_DAY
          is_datefilter_set = true
        elsif beginning_of_calendar.blank? and end_of_calendar.present?
          first_date_last_month = p_param.blank? ? Date.generate_from(end_of_calendar).to_time :
                                             edate
          first_date_begin_month = first_date_last_month.ago no_of_days_to_show * SECONDS_IN_DAY
          is_datefilter_set = true
        elsif beginning_of_calendar.present? and end_of_calendar.present?
          if beginning_of_calendar.to_date > sdate.to_date && end_of_calendar.to_date < edate.to_date
            first_date_begin_month = Date.generate_from(beginning_of_calendar).to_time
            first_date_last_month = Date.generate_from(end_of_calendar).to_time
          else
            first_date_begin_month = p_param.blank? ? Date.generate_from(beginning_of_calendar).to_time : sdate
            first_date_last_month = first_date_begin_month + no_of_days_to_show * SECONDS_IN_DAY
          end
          is_datefilter_set = true
        elsif beginning_of_calendar.blank? and end_of_calendar.blank?
          first_date_begin_month = sdate
          first_date_last_month = sdate + no_of_days_to_show * SECONDS_IN_DAY
        end
      elsif unit == "w" # Make necessary changes for week view
        is_datefilter_set = false
        if beginning_of_calendar.present? and end_of_calendar.blank?
          first_date_begin_month = p_param.blank? ? Date.generate_from(beginning_of_calendar).to_time :
                                              sdate
          first_date_last_month = first_date_begin_month + no_of_weeks_to_show * SECONDS_IN_WEEK
          is_datefilter_set = true
        elsif beginning_of_calendar.blank? and end_of_calendar.present?
          first_date_last_month = p_param.blank? ? Date.generate_from(end_of_calendar).to_time :
                                             edate
          first_date_begin_month = first_date_last_month.weeks_ago no_of_weeks_to_show
          is_datefilter_set = true
        elsif beginning_of_calendar.present? and end_of_calendar.present?
          if beginning_of_calendar.to_date > sdate.to_date && end_of_calendar.to_date < edate.to_date
            first_date_begin_month = Date.generate_from(beginning_of_calendar).to_time
            first_date_last_month = Date.generate_from(end_of_calendar).to_time
          else
            first_date_begin_month = p_param.blank? ? Date.generate_from(beginning_of_calendar).to_time :
                                                sdate
            first_date_last_month = first_date_begin_month + no_of_weeks_to_show * SECONDS_IN_WEEK
          end
          is_datefilter_set = true
        elsif beginning_of_calendar.blank? and end_of_calendar.blank?
          first_date_begin_month = sdate
          first_date_last_month = sdate + no_of_weeks_to_show * SECONDS_IN_WEEK
        end
      end
    end

    # Setting new start and end dates based on direction of pagination.

    if p_param == "L" and unit == "m"
      first_date_begin_month = first_date_begin_month.months_ago 1
      first_date_last_month = first_date_last_month.months_ago 1
    elsif p_param == "L" and unit == "d"
      first_date_begin_month = first_date_begin_month - SECONDS_IN_DAY
      first_date_last_month = first_date_last_month - SECONDS_IN_DAY
    elsif p_param == "R" and unit == "m"
      first_date_begin_month = first_date_begin_month.months_since 1
      first_date_last_month = first_date_last_month.months_since 1
    elsif p_param == "R" and unit == "d"
      first_date_begin_month = first_date_begin_month + SECONDS_IN_DAY
      first_date_last_month = first_date_last_month + SECONDS_IN_DAY
    elsif p_param == "L" and unit == "w"
      first_date_begin_month = first_date_begin_month - SECONDS_IN_WEEK
      first_date_last_month = first_date_last_month - SECONDS_IN_WEEK
    elsif p_param == "R" and unit == "w"
      first_date_begin_month = first_date_begin_month + SECONDS_IN_WEEK
      first_date_last_month = first_date_last_month + SECONDS_IN_WEEK
    end

    [ first_date_begin_month, first_date_last_month ]
  end
end
