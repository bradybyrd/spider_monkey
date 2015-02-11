# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'will_paginate/array'
module TicketsHelper
  
  # FIXME: having this logic in a helper makes the tickets controller a bit hard to follow
  # as complex stuff happens in here with params which are not passed, but assumed to exist
  def paginate_tickets(tickets, per_page = 5, search_keyword=nil)

    @page = params[:page] || 1

    # check for conditions that lead to a full page reload of all tickets

    @filters = params[:filters]
    
    tickets = Ticket.filtered(tickets, @filters,search_keyword)

    if !tickets.blank?
      ret_tickets = nil
      cur_page = @page.to_i
      while (ret_tickets.blank? && cur_page > 0)
        ret_tickets = tickets.paginate( :page => cur_page, :per_page => per_page)
        cur_page = cur_page - 1
      end
      @page = cur_page + 1
    else
      ret_tickets = tickets.paginate(:page => @page, :per_page => per_page)
    end
    ret_tickets
  end
  
  def get_extended_attribute_translations(ticket)
    ret = {}
    details = ticket.project_server.try(:details)
    config = YAML.load(details) if details rescue nil
    if config && config['field_resource_automations']
      config['field_resource_automations'].each_pair do |key, value|
        if config['field_resource_automations'][key]['field_type'] == "extended"
          external_script = Script.find_by_unique_identifier(config['field_resource_automations'][key]['external_resource']) rescue nil
          external_script_output = execute_automation_internal(Step.new, external_script, {}, nil, 0, 0) if external_script rescue nil
          if external_script_output
            reverse_hash = {}
            external_script_output.each do |hsh|
              hsh.each_pair do |key, value|
                reverse_hash[value.to_s]=key
              end
            end
            ret[key] = reverse_hash
          end
        end
      end
    end
    ret
  end
end
