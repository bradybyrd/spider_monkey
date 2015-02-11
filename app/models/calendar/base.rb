################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module Calendar
  class Base
    DEFAULT_FIRST_DAY_ON_CALENDAR = 1

    def first_day_on_calendar
      User.current_user && User.current_user.first_day_on_calendar || DEFAULT_FIRST_DAY_ON_CALENDAR
    end

    def rotated_week_days
      week_days.rotate(first_day_on_calendar)
    end
  end
end
