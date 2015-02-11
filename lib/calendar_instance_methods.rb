################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module CalendarInstanceMethods
  
  def calendar_ready?
    calendar_time_source.to_bool
  end

  def calendar_order_time
    calendar_time_source && send(calendar_time_source)
  end

  def calendar_order_date
    calendar_order_time && calendar_order_time.to_date
  end
  
end
