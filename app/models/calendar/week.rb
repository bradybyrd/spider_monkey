################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module Calendar
  class Week < Calendar::Base
    include DataMethods

    attr_reader   :days,:date
    attr_accessor :month, :filters, :temp_filters, :plan
    alias container month
    alias container= month=

    def self.covering_range(*range)
      range.flatten!
      weeks = []
      (range.min.beginning_of_week(:sunday)..range.max.end_of_week(:sunday)).step(7) do |date|
        weeks << new(date)
      end
      weeks
    end

    def type
      'week'
    end

    def first_day
      days.first
    end

    def last_day
      days.last
    end

    def initialize(date = nil)
      @date = date.present? ? date.to_date : Date.today
      start_date = @date.beginning_of_week(:sunday)
      @days = ((start_date + first_day_on_calendar)..(start_date.end_of_week(:sunday) + first_day_on_calendar)).to_a.map do |date|
        day = date.to_calendar_day
        day.week = self
        day
      end
    end

    def title
      [first_day.strftime('%B'), last_day.strftime('%B')].uniq.join(' - ')
    end

    def requests(day=nil)
      @requests ||= if month
        month.requests(self)
      else
        get_requests
      end.group_by(&:calendar_order_date)

      day ? (@requests[day] || []) : @requests.values.flatten
    end

    def releases(day=nil)
      @releases ||= if month
        month.releases(self)
      else
        get_releases
      end.group_by(&:calendar_order_date)
      day ? (@releases[day] || []) : @releases.values.flatten
    end
  end
end
