################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Time
  include TimeExtensions

  def default_format
    strftime(GlobalSettings[:default_date_format])
  end

  def default_date_format
    strftime(GlobalSettings[:default_date_format].match(/\S+/)[0])
  end
  
  # added this to handle times when oracle returns a DATE field 
  # and rails assumes it is a time, and one of our common format 
  # helpers throws an application error (method not found on Time)
  def default_format_date
    self.strftime(GlobalSettings[:default_date_format]).split(' ')[0]
  end

  def default_time_format
    strftime(GlobalSettings[:default_date_format].match(/\S+\s(\S+)/)[1])
  end
end
