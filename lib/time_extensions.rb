################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module TimeExtensions
  %w(short_year day_of day_of_year day_of_this_year).each do |meth|
    define_method(meth) do |*args|
      self.to_date.send(meth, *args)
    end
  end

  def beginning_of_quarter_hour
    self - minutes_into_quarter_hour.minutes - sec
  end

  def end_of_quarter_hour
    beginning_of_quarter_hour + 15.minutes - 1
  end

  def minutes_into_quarter_hour
    min % 15
  end

  def minutes_until_next_quarter_hour
    15 - minutes_into_quarter_hour
  end

  def seconds_until_next_quarter_hour
    minutes_until_next_quarter_hour * 60 - sec
  end

  def seconds_into_quarter_hour
    minutes_into_quarter_hour * 60 + sec
  end
  
  def default_format_date_time
    self.strftime(GlobalSettings[:default_date_format])
  end
  
  def default_format_date
    self.strftime($system_settings["default_date_format"]).split(' ')[0]
  end
end
