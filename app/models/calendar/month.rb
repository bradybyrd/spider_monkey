################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module Calendar
  class Month < Calendar::Base
    include DataMethods

    attr_accessor :filters, :plan
    attr_reader   :weeks, :start_date, :end_date,:date

    def initialize(date=nil)
      @date = date.present? ? date.to_date : Date.today
      @start_date = Calendar::Day.build @date.beginning_of_month
      @end_date = Calendar::Day.build @date.end_of_month
      @weeks = build_weeks
      unshift_weeks!
    end

    def title
      first_day.strftime('%B')
    end

    def type
      'month'
    end

    def first_day
      @start_date
    end

    def last_day
      @end_date
    end

    def requests(week=nil)
      @requests ||= get_requests.includes({apps: :teams}, {plan_member: :plan}, :environment, :package_contents, :business_process, :release, :owner)

      if week
        @requests.select { |r| r.calendar_order_date.try(:between?, week.first_day.to_date, week.last_day.to_date) }
      else
        @requests
      end

    end

    def releases(week=nil)
      @releases ||= get_releases
      if week
        @releases.select { |r| r.calendar_order_date.try(:between?, week.first_day, week.last_day) }
      else
        @releases
      end
    end

  private

    def build_weeks
      Week.covering_range(@start_date, @end_date).each do |w|
        w.month = self
      end
    end

    def unshift_weeks!
      if @weeks.first.days.first.day != 1 && @weeks.first.days.first.month == @start_date.month
        ((@weeks.first.days.first - 7)..(@weeks.first.days.first - 1)).step(7) do |date|
          @weeks.unshift(Calendar::Week.new(date))
        end
      end
    end
  end
end
