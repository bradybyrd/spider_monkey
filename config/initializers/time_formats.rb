################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

new_formats = {
  :standard  => '%B %d, %Y @ %I:%M %p',
  :stub      => '%B %d',
  :stub_with_short_months      => '%b %d',
  :stub_with_short_months_and_year => '%b %d %y',
  :time_only => '%I:%M%p',
  :plain     => '%B %d %I:%M %p',
  :mdy       => '%B %d, %Y',
  :human_mdy => '%A, %B %d, %Y',
  :human_mdy_short => '%a %b %d, %Y',
  :md        => '%b %d',
  :mdy       => '%b %d, %Y',
  :month     => '%B',
  :my        => '%B %Y',
  :simple    => '%m/%d/%Y',
  :datepicker => '%m/%d/%Y %I:%M %p',
  :unix      => '%m%d',
  :year      => '%y',
  :audit     => '%m-%d-%Y %H:%M:%S.000',
  :mondy     => '%b-%d-%Y',
  :euro      => '%d/%m/%Y %I:%M %p',
  :yearmd    => '%Y/%m/%d %I:%M %p',
  :short_audit => '%b %d %H:%M:%S'
}
Time::DATE_FORMATS.merge! new_formats
Date::DATE_FORMATS.merge! new_formats

