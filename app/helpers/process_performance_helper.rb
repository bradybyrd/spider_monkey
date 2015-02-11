################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ProcessPerformanceHelper
  def full_chart_path(path, extra_params = {})
    full_path = path
    unless extra_params.empty?
      filters = extra_params.delete(:filters)

      full_path << '?'
      extra_params.each do |key, val|
        full_path << "#{key}=#{val}&"
      end

      (filters || []).each do |filter, ids|
        ids.each do |id|
          full_path << "filters[#{filter}][]=#{id}&"
        end
      end
    end
    full_path
  end

  def processes_array
    BusinessProcess.unarchived.collect {|p| [p.id, p.name, BusinessProcess::ColorCodes[p.id]] }
  end

  def current_report?(options={})
    current_link?(controller_name, options) ? "current_page" : ""
  end

end

