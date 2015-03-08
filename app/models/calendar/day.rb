################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

module Calendar
  class Day < Calendar::Base
    include DataMethods
    include DateCompatible

    attr_writer :week, :filters
    attr_reader :week, :month, :filters, :type, :plan, :date_object
    alias_method :container, :week

    def initialize(*args)
      @type = 'day'
      args = args.reject(&:blank?)
      date = args.empty? ? Date.today : Date.parse(args.join('-'))
      @date_object = Date.new(date.year, date.month, date.day)
    end

    def day?
      true
    end

    def title
      strftime('%B')
    end

    def week_days
      [strftime('%a')]
    end

    %w(releases requests).each do |data_type|
      define_method data_type do
        if week
          week.send(data_type, date_object)
        else
          grouped_reqs = send("get_#{data_type}").group_by(&:calendar_order_date)
          grouped_reqs[date_object] || []
        end
      end
    end

    def inspect
      "#{self.class} (#{super})"
    end

    def first_day
      @date_object
    end

    alias_method :last_day, :first_day
    alias_method :to_calendar_day, :first_day

    def self.build(date)
      date = date.strftime('%Y-%m-%d').split('-')
      new(date)
    end
  end
end
