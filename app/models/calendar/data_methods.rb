################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module Calendar
  module DataMethods
    def get_requests
      if plan
        plan.requests
      else
        current_user_requests
      end.functional
         .between_dates(first_day, last_day)
         .filtered(filters)
    end

    def get_requests_between_dates(first_day, last_day)
      Request.functional.between_dates(first_day, last_day).filtered(filters)
    end

    def get_releases
      begin
        ActivityDeliverable.release_deployment.between_dates(first_day, last_day).filtered(add_temp_filters(ActivityDeliverable::SortScope))
      rescue Exception => e
        logger.info e.message
        logger.info e.backtrace
      end
    end

    def week_days
      %w{Sun Mon Tue Wed Thu Fri Sat}
    end

    def day?
      false
    end

    def next
      self.class.new(last_day + 1)
    end

    def previous
      self.class.new(first_day - 1)
    end

    def to_param
      first_day.to_s(:db)
    end

    def include?(day)
      (first_day..last_day).include?(day)
    end

    def nil_or_empty?
      false
    end

  private

    def current_user_requests
      User.current_user && User.current_user.requests(true) || Request.none
    end
  end
end
