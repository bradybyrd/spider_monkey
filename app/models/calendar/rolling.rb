################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module Calendar
  class Rolling < Calendar::Base
    include DataMethods
    attr_reader   :weeks,:date
    attr_accessor :filters, :temp_filters, :plan

    def type
      'rolling'
    end

    def first_day
      weeks.first.first_day
    end

    def last_day
      weeks.last.last_day
    end

    def initialize(date = nil)
      @date = date.present? ? date.to_date : Date.today
      end_date = @date + 3.weeks
      @weeks = Week.covering_range(@date, end_date).each do |w|
        w.container = self
      end
    end

    def next
      self.class.new(first_day + 1.week)
    end

    def previous
      self.class.new(first_day - 1.week)
    end

    def title
      [first_day.strftime('%B'), last_day.strftime('%B')].uniq.join(' - ')
    end

    def requests(week = nil)
      @requests ||= get_requests

      if week
        @requests.select { |r| r.calendar_order_date.try(:between?, week.first_day.to_date, week.last_day.to_date) }
      else
        @requests
      end

    end

    def releases(week = nil)
      @releases ||= get_releases
      if week
        @releases.select { |r| r.calendar_order_date.try(:between?, week.first_day, week.last_day) }
      else
        @releases
      end
    end

  end
end
