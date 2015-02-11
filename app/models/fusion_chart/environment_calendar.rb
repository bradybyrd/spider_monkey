################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################


class FusionChart

  def environment_calendar(filters, p = nil, sdate = nil, edate = nil, unit = nil, beginning_of_calendar = nil, end_of_calendar = nil, width = nil)
   screen_width = width.blank? ? 1024 : width
   usable_width = screen_width

   month_def_width = 200
   day_def_width = 75
   week_def_width = 200

   no_of_months_to_show = (usable_width/month_def_width).floor
   no_of_days_to_show = (usable_width/day_def_width).floor
   no_of_weeks_to_show = (usable_width/week_def_width).floor

    if sdate.blank? and edate.blank?
     first_date_last_month = (Time.now).at_end_of_month
     first_date_begin_month = first_date_last_month.months_ago(no_of_months_to_show - 1).at_beginning_of_month
   else

       if(unit == "m")
         is_datefilter_set = false
          if beginning_of_calendar.present? and end_of_calendar.blank?
            first_date_begin_month = p.blank? ? Date.generate_from(beginning_of_calendar).to_time.at_beginning_of_month : sdate.at_beginning_of_month
            first_date_last_month = first_date_begin_month.months_since(no_of_months_to_show - 1).at_end_of_month
            is_datefilter_set = true
          elsif beginning_of_calendar.blank? and end_of_calendar.present?
            first_date_last_month = p.blank? ? Date.generate_from(end_of_calendar).to_time.at_end_of_month : edate.at_end_of_month
            first_date_begin_month = first_date_last_month.months_ago(no_of_months_to_show - 1).at_beginning_of_month
            is_datefilter_set = true
          elsif beginning_of_calendar.present? and end_of_calendar.present?
            if((beginning_of_calendar.to_date > sdate.at_beginning_of_month.to_date) && (end_of_calendar.to_date < edate.at_end_of_month.to_date))
             first_date_begin_month = Date.generate_from(beginning_of_calendar).to_time
             first_date_last_month = Date.generate_from(end_of_calendar).to_time
            else
              first_date_begin_month = p.blank? ? Date.generate_from(beginning_of_calendar).to_time.at_beginning_of_month : sdate.at_beginning_of_month
              first_date_last_month = (Date.generate_from(end_of_calendar).to_time < first_date_begin_month.months_since(no_of_months_to_show - 1).at_end_of_month) ? Date.generate_from(end_of_calendar).to_time : first_date_begin_month.months_since(no_of_months_to_show - 1).at_end_of_month
            end
            is_datefilter_set = true
          elsif beginning_of_calendar.blank? and end_of_calendar.blank?
            first_date_begin_month = sdate.at_beginning_of_month
            first_date_last_month = first_date_begin_month.months_since(no_of_months_to_show - 1).at_end_of_month
          end
      elsif(unit == "d")
          is_datefilter_set = false
        if beginning_of_calendar.present? and end_of_calendar.blank?
          first_date_begin_month = p.blank? ? Date.generate_from(beginning_of_calendar).to_time : sdate
          first_date_last_month = (first_date_begin_month + (no_of_days_to_show * 24 * 60 * 60))
          is_datefilter_set = true
        elsif beginning_of_calendar.blank? and end_of_calendar.present?
          first_date_last_month = p.blank? ? Date.generate_from(end_of_calendar).to_time : edate
          first_date_begin_month = first_date_last_month.ago(no_of_days_to_show * 24 * 60 * 60)
          is_datefilter_set = true
        elsif beginning_of_calendar.present? and end_of_calendar.present?
          if((beginning_of_calendar.to_date > sdate.to_date) && (end_of_calendar.to_date < edate.to_date))
           first_date_begin_month = Date.generate_from(beginning_of_calendar).to_time
           first_date_last_month = Date.generate_from(end_of_calendar).to_time
          else
           first_date_begin_month = p.blank? ? Date.generate_from(beginning_of_calendar).to_time : sdate
           first_date_last_month = (first_date_begin_month + (no_of_days_to_show * 24 * 60 * 60))
          end
          is_datefilter_set = true
        elsif beginning_of_calendar.blank? and end_of_calendar.blank?
          first_date_begin_month = sdate
          first_date_last_month = sdate + (no_of_days_to_show * 24 * 60 * 60)
        end
      elsif(unit == "w")                                             # Make necessary changes for week view
          is_datefilter_set = false
        if beginning_of_calendar.present? and end_of_calendar.blank?
          first_date_begin_month = p.blank? ? Date.generate_from(beginning_of_calendar).to_time : sdate
          first_date_last_month = (first_date_begin_month + (no_of_weeks_to_show * 7 * 24 * 60 * 60))
          is_datefilter_set = true
        elsif beginning_of_calendar.blank? and end_of_calendar.present?
          first_date_last_month = p.blank? ? Date.generate_from(end_of_calendar).to_time : edate
          first_date_begin_month = first_date_last_month.weeks_ago(no_of_weeks_to_show)
          is_datefilter_set = true
        elsif beginning_of_calendar.present? and end_of_calendar.present?
          if((beginning_of_calendar.to_date > sdate.to_date) && (end_of_calendar.to_date < edate.to_date))
           first_date_begin_month = Date.generate_from(beginning_of_calendar).to_time
           first_date_last_month = Date.generate_from(end_of_calendar).to_time
          else
           first_date_begin_month = p.blank? ? Date.generate_from(beginning_of_calendar).to_time : sdate
           first_date_last_month = (first_date_begin_month + (no_of_weeks_to_show * 7 * 24 * 60 * 60))
          end
          is_datefilter_set = true
        elsif beginning_of_calendar.blank? and end_of_calendar.blank?
          first_date_begin_month = sdate
          first_date_last_month = sdate + (no_of_weeks_to_show * 7 * 24 * 60 * 60)
        end
      end

   end

   # Setting new start and end dates based on direction of pagination.
       if p == "L" and (unit == "m")
          first_date_begin_month = first_date_begin_month.months_ago(1)
          first_date_last_month = first_date_last_month.months_ago(1)
        elsif p == "L" and (unit == "d")
          first_date_begin_month = first_date_begin_month - (24 * 60 * 60)
          first_date_last_month = first_date_last_month - (24 * 60 * 60)
        elsif p == "R" and (unit == "m")
          first_date_begin_month = first_date_begin_month.months_since(1)
          first_date_last_month = first_date_last_month.months_since(1)
        elsif p == "R" and (unit == "d")
          first_date_begin_month = first_date_begin_month + (24 * 60 * 60)
          first_date_last_month = first_date_last_month + (24 * 60 * 60)
        elsif p == "L" and (unit == "w")
          first_date_begin_month = first_date_begin_month - (7 * 24 * 60 * 60)
          first_date_last_month = first_date_last_month - (7 * 24 * 60 * 60)
        elsif p == "R" and (unit == "w")
          first_date_begin_month = first_date_begin_month + (7 * 24 * 60 * 60)
          first_date_last_month = first_date_last_month + (7 * 24 * 60 * 60)
        end

   startd = first_date_begin_month
   endd = first_date_last_month

#   puts " In env_cal.rb file -- DATA $$$$$$$$$==== #{first_date_begin_month} ------to #{first_date_last_month}"

    if filters and filters[:environment_id].present?
     @environments = User.current_user.accessible_environments.includes(:plan_env_app_dates).where(:id => filters[:environment_id])
    else
     @environments = User.current_user.accessible_environments.includes(:plan_env_app_dates)
    end

    @env_plans = Hash.new

    if (filters && filters[:aasm_state].present?)
      plans = Plan.entitled(User.current_user).select("plans.id").where("plans.aasm_state!= ?", "deleted").where(conditions_for_plans).all.map(&:id)
    else
      plans = Plan.entitled(User.current_user).select("plans.id").where("plans.aasm_state!= ?", "deleted").all.map(&:id)
    end

   @environments = @environments.all
   if startd.present? and endd.blank?
     planenvappdates =  PlanEnvAppDate.where(:environment_id => @environments.map(&:id)).where(finder_opts_for_calendar).where("planned_complete >= ?", startd)
   elsif startd.blank? and endd.present?
     planenvappdates = PlanEnvAppDate.where(:environment_id => @environments.map(&:id)).where(finder_opts_for_calendar).where("planned_start <= ?", endd)
   elsif startd.present? and endd.present?
     planenvappdates = PlanEnvAppDate.where(:environment_id => @environments.map(&:id)).where(finder_opts_for_calendar).between_to_from(startd, endd)
   elsif startd.blank? and endd.blank?
     planenvappdates = PlanEnvAppDate.where(:environment_id => @environments.map(&:id)).where(finder_opts_for_calendar)
   end
   env_app_dates = planenvappdates.order("planned_start").all
      @environments.each do |env|
        array = []
        plan_ids = []
        dis_env_app_dates = env_app_dates.select{|v| v.environment_id == env.id}
        dis_env_app_dates.each do |env_app_date|
             array << ([env_app_date.planned_start, env_app_date.planned_complete, env_app_date.plan, env_app_dates.last.planned_complete, env_app_date.app_id]) if plans.include?(env_app_date.plan_id)
             plan_ids << env_app_date.plan_id if plans.include?(env_app_date.plan_id)
        end
        plan_ids.uniq!
        array << plan_ids
        @env_plans[env] = array
      end
      @env_plans["p"] = p if p.present?
      @env_plans
    end

end
