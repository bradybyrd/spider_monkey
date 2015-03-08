################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

class CalendarReport < ActiveRecord::Base

  validates :team_name, presence: true, uniqueness: true
  validates :report_url, presence: true, uniqueness: true
  
end
