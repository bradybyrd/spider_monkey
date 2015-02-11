################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module AlphabeticalPaginator

  DEFAULT_PER_PAGE = 20

  def alphabetical_paginator(records_per_page, records = nil, inactive = false)
    page_name = inactive ? :page_inactive : :page
    total_records = records.size.to_f
    per_page = records_per_page
    offset = 0
    total_pages = (total_records/per_page.to_f).ceil
    pages = {}
    records_arr = records.to_a
    total_pages.times do
      lower_bound_obj = records_arr[offset]      
      lower_bound = get_bound_name(lower_bound_obj)
      upper_bound_idx = offset + per_page
      if upper_bound_idx > total_records
        upper_bound_idx = offset + (total_records - per_page * (total_pages - 1))
      end
      upper_bound_obj = records_arr[upper_bound_idx - 1]
      upper_bound = get_bound_name(upper_bound_obj)
      pages.merge!(offset => "#{lower_bound}-#{upper_bound}")
      offset = upper_bound_idx
    end
    if params[page_name].blank?
      active_records = records.offset(0).limit(per_page).all.uniq
      next_page = per_page
    else
      active_records = records.offset(params[page_name].to_i).limit(per_page).all
      next_page = params[page_name].to_i + per_page
      next_page = next_page < total_records.to_i ? next_page : params[page_name].to_i
      previous_page = params[page_name].to_i - per_page
      previous_page = params[page_name] == '0' ? params[page_name].to_i : previous_page
    end
    if inactive
      @pages_inactive =         pages
      @next_page_inactive =     next_page
      @previous_page_inactive = previous_page
    else
      @pages =         pages
      @next_page =     next_page
      @previous_page = previous_page
    end
    active_records
  end

  private

  def get_bound_name(bound_obj)
    bound_obj ? bound_obj.name.slice(0, 3).capitalize : ''
  end

end
