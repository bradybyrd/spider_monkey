################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ResourcesHelper
  def resource_allocation_input_tds stream, months_ago, months_from_now
    Date.act_on_month_range(months_ago, months_from_now) do |month, year| 
      selected_option = stream ? stream.allocation_for_year_and_month(year, month) : 0

      element = "<td> "
      element << select_tag("allocations[#{stream.id}][#{year}][#{month}]", options_for_select((0..100).step(5), selected_option ))
      element << "</td>"
      element
    end
  end

  def yearstring month_name, index, months_ago, months_from_now
    str = ''
    str = ", #{(@months_ago).months.ago.short_year}" if index.zero?
    str = ", #{(@months_from_now).months.from_now.short_year}" if month_name == "Jan"
    str
  end
  
  def total_value_class(value)
    if value <= 90
      'under'
    elsif value >= 110
      'over'
    end
  end 

  def resource_location_options selected = nil
    options_for_select List.get_list_items("Locations").sort.map { |l| [l.upcase, l] }, selected
  end

  def resource_role_options selected = nil
    options_for_select User::Roles.map { |r| [r.titleize, r] }, selected
  end
  
  def sortable(title, sort_by,group,status = nil)
    classes = "desc"
    if status.blank?
      link_to_remote "#{title}", :url => allocations_by_group_resource_path(group, :sortable => sort_by, :sort => classes,:status => status), :method => :get, :loading => "$('##{sort_by}_loader_#{group.id}').show();", :complete => "$('##{sort_by}_loader_#{group.id}').hide();", :html => {:class =>  classes, :id => "#{sort_by}_#{group.id}"}
    else
      link_to_remote "#{title}", :url => allocations_by_group_resource_path(group, :sortable => sort_by, :sort => classes,:status => status), :method => :get, :loading => "$('##{sort_by}_#{status}_loader_#{group.id}').show();", :complete => "$('##{sort_by}_#{status}_loader_#{group.id}').hide();", :html => {:class =>  classes, :id => "#{sort_by}_#{group.id}"}
    end
  end

  def fetch_allocations(act_id, user_id, teamallocations)
    result = Array.new(12,0)
    today = Date.current
    cur_year = today.year
    rng = Date.month_range(5,6)
    months = ResourceAllocation.month_range_names(5,6)
    teamallocations.reject{ |c| c.resource_id != user_id }.reject{ |c| c.activity_id != act_id }.each do |alloc|
      rng.each_with_index do |mon, cnt|
        if mon < 0 && alloc.year == cur_year -1
          result[cnt] = allocation_for_month(mon+12, alloc)
        elsif mon >= 0 && alloc.year == cur_year
          result[cnt] = allocation_for_month(mon, alloc)
        end
      end
    end
    return result 
  end    
  
  def fetch_allocation_totals(user_id, teamallocations)
    result = Array.new(12,0)
    today = Date.current
    cur_year = today.year
    rng = Date.month_range(5,6)
    months = ResourceAllocation.month_range_names(5,6)
    gid = teamallocations[1].resource_id.class == String ? user_id.to_s : user_id.to_i
    teamallocations.reject{ |c| c.resource_id != gid }.each do |alloc|
      rng.each_with_index do |mon, cnt|
        if mon < 0 && alloc.year == cur_year -1
          result[cnt] += allocation_for_month(mon+12, alloc)
        elsif mon >= 0 && alloc.year == cur_year
          result[cnt] += allocation_for_month(mon, alloc)
        end
      end
    end
    return result
  end
  
  def allocations_include_group(group_id, teamallocations)
    gid = teamallocations[1].group_id.class == String ? group_id.to_s : group_id.to_i
    result = false
    teamallocations.reject{ |c| c.group_id != gid }.each do |alloc|
      result = true
    end
    result
  end

  def allocation_for_month(month_no, allocation)
    result = case month_no
      when 0 then allocation.jan
      when 1 then allocation.feb
      when 2 then allocation.mar
      when 3 then allocation.apr
      when 4 then allocation.may
      when 5 then allocation.jun
      when 6 then allocation.jul
      when 7 then allocation.aug
      when 8 then allocation.sep
      when 9 then allocation.oct
      when 10 then allocation.nov
      when 11 then allocation.dec
    end
    return result.to_i
  end
    
  def group_toggle_link_text(group, is_open)
    return <<-zEND
     <h3 id="toggle_group_#{group.id}" style="border-top:none;" class="toggle #{ is_open ? "open" : "closed" } preserve resource">#{group.name} </h3>
    zEND
  end

end
