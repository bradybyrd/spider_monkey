class Ticket < ActiveRecord::Base

  scope :by_ticket_type, lambda { |types| where(:ticket_type => types) }
  scope :by_foreign_id, lambda { |foreign_id| where(:foreign_id => foreign_id).order(:foreign_id) }
  scope :by_app_id, lambda { |app_id| where(:app_id => app_id)}
  scope :by_app_name, lambda { |app_name| { :include => :app, :conditions => ['apps.name LIKE ? OR apps.name LIKE ?', app_name, "#{app_name}_|%" ]}}
  #scope :active, where(:active => true)
  #scope :inactive, where(:active => false)
  scope :by_integration, lambda { |integration| joins(:project_server).where("project_servers.id" => integration) }
  scope :by_status ,lambda {|status| where(:status => status) }
  scope :by_request_id, lambda { |request_id| joins(:steps).where("steps.request_id" => request_id) }
  # This is a redundant scope, We could use the generic scope from LinkedItem instead
  scope :by_step_id, lambda { |step_id| joins(:steps).where("steps.id" => step_id) }

  # This is a redundant scope, We could use the generic scope from LinkedItem instead
  scope :by_plan_id, lambda {|plan_id| joins(:plans).where("plans.id" => plan_id) }

  def self.filtered(tickets = nil, filters = {},search_keyword=nil)
  
    if tickets.blank?
      tickets = self
    end
    unless filters.blank?
      unless filters[:ticket_type].blank?
        ticket_types = Ticket.types_for_select
        filters[:ticket_type].delete_if {|t| !ticket_types.include?(t) }
        tickets = tickets.by_ticket_type(filters[:ticket_type]) unless filters[:ticket_type].blank?
      end
      tickets = tickets.by_integration(filters[:project_server_id]) unless filters[:project_server_id].blank?
      tickets = tickets.by_foreign_id(filters[:foreign_id]) unless filters[:foreign_id].blank?
      tickets = tickets.by_request_id(filters[:request_id]) unless filters[:request_id].blank?
      tickets = tickets.by_step_id(filters[:step_id]) unless filters[:step_id].blank?
      tickets = tickets.by_plan_id(filters[:plan_id]) unless filters[:plan_id].blank?
      tickets = tickets.by_app_id(filters[:app_id]) unless filters[:app_id].blank?
      tickets = tickets.by_app_name(filters[:app_name]) unless filters[:app_name].blank?
      # since we implemented resource automation for status values vs. underlying codes, we need to handle this
      # in our filters too.  This method should pass non-lookup values through to the tickets filter, but 
      # provide codes for any with project servers that provide values
      tickets = tickets.by_status( filters[:ticket_status] ) unless filters[:ticket_status].blank?
      if ((filters[:sort_scope].present?) && (filters[:sort_scope] != 'false'))
        tickets = tickets.sorted_by(filters[:sort_scope], filters[:sort_direction] == 'asc')
      end
    end

    #filtering tickets based on search parameters
    tickets = tickets.where("UPPER(tickets.name) like '%#{search_keyword.upcase}%' or UPPER(tickets.foreign_id) like '%#{search_keyword.upcase}%'") unless search_keyword.blank?
    
    if tickets == self
      tickets = self.all
    end
    return tickets
  end

  scope :sorted, order('name')

end
