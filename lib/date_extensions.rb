################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module DateExtensions
  def self.included(target)
    target.extend ClassMethods
  end

  def to_calendar_day
    Calendar::Day.new(year, month, day)
  end

  def beginning_of_week
    self - wday
  end

  def day_of(year)
    (self - Date.new(year)).to_i
  end

  def day_of_year
    day_of self.year
  end

  def day_of_this_year
    day_of Date.today.year
  end

  def end_of_week
    self + (6 - wday)
  end

  def weekday?
    (1..5).member? wday
  end

  def weekend?
    !weekday?
  end

  def short_year
    "'#{year.to_s.last(2)}"
  end

  def default_format_date
    self.strftime(GlobalSettings[:default_date_format]).split(' ')[0]
  end

  def nil_or_empty?
    false
  end

  module ClassMethods
    def month_range(months_ago, months_from_now)
      this_month = today.month
      ((this_month - months_ago - 1)...(this_month + months_from_now))
    end

    def act_on_month_range(months_ago, months_from_now, &block)
      month_range(months_ago, months_from_now).map do |mon|
        case block.arity
        when 1
          yield normalize_month(mon)
        else
          yield normalize_month(mon), year_from_month(mon)
        end
      end
    end

    # Given months 0-11 are Jan-Dec of the current year
    # Return value will be within 1..12
    def normalize_month(month)
      month % 12 + 1
    end

    def year_from_month(month)
      # Given months 0-11 are Jan-Dec of the current year
      today.year + month / 12
    end

    # This is required to standarize date format when
    # default date format is changed and not in default format readily accepted by system
    def generate_from(given_date)
      return given_date if given_date.is_a?(Date)
      system_settings_date = GlobalSettings[:default_date_format]
      default_date_format = if system_settings_date.present?
        system_settings_date
      else
        "%m/%d/%Y"
      end.gsub("%I:%M %p", "")

      split_by = default_date_format.include?("-") ?  "-" : "/"

      split_date_format = default_date_format.split(split_by).collect {
        |e| e.gsub(/[^A-Za-z]/, '')}.select{|p| p.length > 0}
      d = split_date_format.index('d') # day of month
      m = split_date_format.index('m') # month number
      y = split_date_format.index('Y') # year
      b = split_date_format.index('b') # month in text like Dec, Jan

      split_given_date = given_date.split(split_by)
      if split_given_date[y].to_i < 40 # Failsafe not the proper fmt
        if y == 0 and split_given_date[2].to_i > 40
          if split_given_date[1].length == 3
            m = 1; y = 2; d = 0 # dd/mmm/yyyy
          elsif split_given_date[0].length == 3
            m = 0; y = 2; d = 1 #mmm/dd/yyyy
          elsif split_given_date[0].to_i < 12
            y = 2; m = 0; d = 1 # mm/dd/yyyy
          else
            y = 2; m = 1; d = 0 # dd/mm/yyyy
          end
        else
          y = 0; m = 1; d = 2 # yyyy-mm-dd
        end
      end

      month = if split_by == "-"
        Date::ABBR_MONTHNAMES.index(split_given_date[b])
      else
        split_given_date[m]
      end.to_i

      Date.new(split_given_date[y].to_i, month, split_given_date[d].to_i)
    end

  end
end
