################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'sortable_model'

class Ticket < ActiveRecord::Base
  
  include Messaging
  # adding this so we can eval resource automations
  include ApplicationHelper
  acts_as_messagable

  scope :include_only, lambda {|ids| {:conditions => ["tickets.id IN (?)",ids]}}
  scope :exclude_only, lambda {|ids| {:conditions => ["tickets.id NOT IN (?)",ids]}}
  belongs_to :project_server

  belongs_to :app

  has_many :linked_items, :as => :source_holder, :dependent => :destroy   # This ticket object may have many owners

  has_many :plans, :through => :linked_items, :as => :target_holder,
           :source => :target_holder, :source_type => 'Plan'

  has_many :steps, :through => :linked_items, :as => :target_holder,
    :source => :target_holder, :source_type => 'Step'

  #has_many :child_ticket_links, :class_name => 'LinkedItem', :as => :target_holder, :dependent => :destroy
  #has_many :child_tickets, :class_name => 'Ticket', :through => :child_ticket_links, :as => :source_holder, :source => :source_holder, :source_type => 'Ticket'

  #has_many :parent_tickets, :class_name => 'Ticket', :through => :linked_items, :as => :target_holder, :source => :target_holder, :source_type => 'Ticket'
  has_many :related_tickets, :class_name => 'Ticket', :through => :linked_items, :as => :target_holder, :source => :target_holder, :source_type => 'Ticket'

  has_many :extended_attributes, :as => :value_holder, :dependent => :destroy

  accepts_nested_attributes_for :extended_attributes

  validates :foreign_id,
            :presence => true,
            :uniqueness => {:scope => :project_server_id,:message =>'of the ticket for the given integration has already been taken up.'},
            :length => {:maximum => 50}
  validates :name,
            :presence => true,
            :length => {:maximum => 250}
  validates :status,
            :presence => true ,
            :length => {:maximum => 125}
  validates :project_server_id ,
            :presence => true
  validates :ticket_type, 
            :length => {:maximum => 100, :allow_blank => true}

  attr_accessor :app_name, :application_lookup_failed,
                :plan_names, :plans_lookup_failed

  validate :lookups_succeeded
  after_update :push_msg

  before_validation :find_application, :find_plans

  normalize_attributes :foreign_id, :ticket_type, :status
  normalize_attributes :url do |url|
    if url.present?
      URI.parse(url).scheme.blank? ? "http://#{url}" : url
    end
  end

  attr_accessible :foreign_id, :name, :status, :ticket_type, :project_server_id, :app_id, :plan_ids, :app_name,
                  :application_lookup_failed, :plan_names, :plans_lookup_failed, :extended_attributes_attributes, :url

  sortable_model

  can_sort_by :name
  can_sort_by :foreign_id
  can_sort_by :status
  can_sort_by :ticket_type
  can_sort_by :app_id, lambda {|asc| includes(:app).order("apps.name #{asc ? "ASC" : "DESC"}") }

  can_sort_by :plan_id, lambda { |asc| includes(:plans).order("plans.name #{asc ? "ASC" : "DESC"}") }

  can_sort_by :project_server_id, lambda{|asc| includes(:project_server).order("project_servers.name #{asc ? "ASC" : "DESC"}")}
  
  concerned_with :ticket_named_scopes
  def self.types_for_select
    #res = connection.select_rows("select distinct (ticket_type) from tickets").flatten
    res = Ticket.all(:select => "DISTINCT ticket_type")
    res.reject{ |tt| tt.ticket_type.nil? }.map { |tt| tt.ticket_type }.sort
  end

  def get_printable_data
    "Id: #{foreign_id}\n\tURL\t\t: #{url}\n\tName\t\t: #{name}\n\tStatus\t\t: #{status}\n\tApp\t\t: #{safe_string(app.try(:name)) }\n\tType\t\t: #{ticket_type}\n\tIntegration\t: #{safe_string(project_server.try(:name))}\n\n"
  end


  # CHKME: Consider any issues with status labels from various project servers colliding,
  # but returning to the simple string usage of status solves a lot of these issues -- it is 
  # just a stub and extended attributes can be used for codes.
  def self.status
    
    tickets = Ticket.select("DISTINCT tickets.status").where('tickets.status IS NOT NULL').order('tickets.status ASC')
    
    # Agreement to do bare tags so no need for a lookup   
    stats_as_string = tickets.map(&:status).reject { |s| s.blank? }.uniq.sort
    
    return stats_as_string
    
  end
  
  # a convenience method on the Ticket class to add selections to the database
  def self.add_tickets_to_plan( plan, project_server, selected_tickets = [], ticket_cache = [] ) 
    
    # create a simple results object to cache progress through the selected ticket list
    results = { :messages => [], :updated_tickets => [], :created_tickets => [], :invalid_ticket_data => [] }
                
    # put the cached data into a searchable form
    potential_mapped_objects = get_full_ticket_objects_from_web_inputs(selected_tickets, ticket_cache)              
    
    if potential_mapped_objects.blank?
      results[:messages] << "Form data could not be processed: problem matching selected tickets to cached query results."
    else               
      # now find or create tickets 
      potential_mapped_objects.each do |potential_ticket_object|                
        # get the unique foreign id and proceed only if you have one
        unique_key = potential_ticket_object[0]       
        if unique_key.blank?     
          results[:messages] << "Form data could not be processed: Ticket row data is missing a unique foreign id field."
        else  
          # map the row data to ticket attributes
          ticket_attributes = map_automation_data_ticket_attributes(potential_ticket_object, project_server)   
          # ensure the attributes pass a sanity check before we try to update or add them
          if sanity_test_on_ticket_attributes( ticket_attributes )
            # update or create a ticket, throwing an error if assigned to a new plan
            results = update_or_create_ticket_with_row_data( unique_key, ticket_attributes, plan, project_server, results )
          else              
            results[:invalid_ticket_data] << ticket_attributes
            results[:messages] << "Invalid Ticket: Ticket with foreign id #{ ticket_attributes[:foreign_id] || "[blank]" } was invalid."
          end
        end
      end
    end
    # record the results message in the log unless blank
    Rails.logger.info("EXTERNAL TICKET IMPORT RESULTS[:MESSAGES]\n" + results[:messages].join("\n")) unless results[:messages].blank?
    Rails.logger.info("EXTERNAL TICKET IMPORT RESULTS[:UPDATED_TICKETS]:\n" + results[:updated_tickets].inspect) unless results[:updated_tickets].blank?
    Rails.logger.info("EXTERNAL TICKET IMPORT RESULTS[:CREATED_TICKETS]:\n" + results[:created_tickets].inspect) unless results[:created_tickets].blank?
    Rails.logger.info("EXTERNAL TICKET IMPORT RESULTS[:CREATED_TICKETS]:\n" + results[:invalid_ticket_data].inspect) unless results[:invalid_ticket_data].blank?
    return results
  end

  private

  
  def safe_string(str)
    str ? str.strip : ''
  end

  # convenience finder (mostly for REST clients) that allows you to pass an app name
  # and have us look up the correct app for you
  def find_application
    unless self.app_name.blank?
      self.app = App.active.by_short_or_long_name(self.app_name).try(:first)
      self.application_lookup_failed = self.app.blank?
    end
    # be sure the call back returns true or else the call will fail with no error message
    return true
  end
  
  # convenience finder (mostly for REST clients) that allows you to pass an array of lifecycle names
  
  # and have us look up the correct plans for you
  def find_plans
    unless self.plan_names.blank?
      my_plans = Plan.by_name(plan_names)
      if my_plans.blank? || my_lifecycles.length < self.plan_names.length
      self.plans_lookup_failed = true
      else
      self.plans = my_plans
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    return true
  end
  
  def lookups_succeeded
    #add validations here to stop execution if necessary
    self.errors.add(:app_name, " was not found in active applications.") if self.application_lookup_failed
    self.errors.add(:plan_names, " had at least one plan name not found in plans.") if self.plans_lookup_failed
  end
  
  # helper method to process the selected tickets array and match it to json encoded tickets
  # passed along with the web form
  def self.get_full_ticket_objects_from_web_inputs( selected_tickets, ticket_cache )
    searchable_cache = ticket_cache.map { |c| JSON.parse(c) }
    indexed_cache = {}
    searchable_cache.map { |s| indexed_cache[s[0]] = s } 
    # now iterate through the selected keys and match it to the cached_data
    potential_mapped_objects = []
    selected_tickets.each do |key|
      potential_mapped_objects << indexed_cache[key] if indexed_cache[key].present?
    end 
    return potential_mapped_objects.uniq
  end
  
  # helper for mapping automation data to ticket attributes
  def self.map_automation_data_ticket_attributes( potential_ticket_object, project_server )  
    # prepare extended attributes from column 6 which should be stored as a json string by the automation
    extended_attributes = prepare_extended_attributes_from_json( potential_ticket_object[5] )      
    # prepare the ticket object based on position in the data array
    # NOTE: the order of fields must stay the same in the resource automation or this will map 
    # the wrong data into each field and ensuring length limits are respected for the fields
    ticket_attributes = { :foreign_id => potential_ticket_object[0][0..50], 
                          :name => potential_ticket_object[1][0..250], 
                          :ticket_type => potential_ticket_object[2][0..100], 
                          :status => potential_ticket_object[3][0..120], 
                          :project_server_id => project_server.try(:id), 
                          :extended_attributes_attributes => extended_attributes }
    return ticket_attributes
  end
  
  # sanity test on ticket attributes so we don't throw active record errors
  def self.sanity_test_on_ticket_attributes( ticket_attributes )
    sane = false
    # run a series of tests and increment the results messaged if invalid data is found
    if ticket_attributes.blank? 
      sane = false
    elsif ticket_attributes[:foreign_id].blank? || !ticket_attributes[:foreign_id].is_a?(String)
      sane = false
    elsif ticket_attributes[:name].blank? || !ticket_attributes[:name].is_a?(String)
      sane = false  
    elsif ticket_attributes[:status].blank? || !ticket_attributes[:status].is_a?(String)
      sane = false   
    elsif ticket_attributes[:project_server_id].blank? || ticket_attributes[:project_server_id] == 0
      sane = false   
    else
      sane = true
    end
    # TODO: add other sanity tests
    return sane
  end
  
  # helper method for making an extended attributes array from a json
  # string, used by ticketing resource automations that need to store extra data
  # with the generic ticket stub.  Empty or invalid data is fine since some
  # systems may not send extended attributes at all, but just fill out the ticket
  # stub fields.
  def self.prepare_extended_attributes_from_json( json_string = "{}" )
    extended_attributes_for_import = []
    if json_string.present? && json_string.is_a?(String)
      extended_attributes_hash = JSON.parse(json_string) rescue []
      # log an error in the logs if the was no json, but continue with an empty array
      Rails.logger.info("EXTERNAL TICKET FILTER: JSON Extended Attributes were empty or invalid.") if extended_attributes_hash.blank?
      extended_attributes_hash.each do |hash_key, value|
        extended_attributes_for_import << { :name => hash_key, :value_text => value }
      end
    end  
    return extended_attributes_for_import  
  end
  
 # helper method to update a ticket with web data if it is found in the database
  def self.update_or_create_ticket_with_row_data( unique_key, ticket_attributes, plan, project_server, results )
    # find the ticket using the foreign key and the project server_id, including the same ticket in another plan
    ticket = Ticket.where(:foreign_id => unique_key, :project_server_id => project_server.id).try(:first)
    
    # proceed with the update if the ticket was found
    unless ticket.blank?
      results = update_ticket_with_row_data( ticket, ticket_attributes, plan, results )
    else
      # or create it if it was not found
      results = create_ticket_with_row_data( ticket_attributes, plan, results )
    end
    return results
  end
  
  # helper method to selectively update a ticket from row data or report failures
  def self.update_ticket_with_row_data( ticket, ticket_attributes, plan, results )
    # cache the unique key
    unique_key = ticket_attributes[:foreign_id]
    
    # if the ticket has no plan assigned to it, add the current plan to its id
    ticket_attributes[:plan_ids] = [plan.id] if ticket.plan_ids.empty?
      
    # check if the ticket belongs to another plan and add an error message to the log
    unless ticket.plan_ids.empty? || ticket.plan_ids.include?(plan.id) 
      results[:invalid_ticket_data] << ticket_attributes
      results[:messages] << "Invalid Ticket: Ticket #{ unique_key} has already been assigned to Plan #{ ticket.plans.first.try(:name) } (#{ticket.plan_ids.first})."
    else
      # proceed with the update
      
      # load the ids for any existing attributes or we will validation errors on attributes
      # sent without the id field, as we are using nested attributes
      ticket_attributes[:extended_attributes_attributes].each do |extended_attribute|
        existing_attribute = ticket.extended_attributes.find_by_name(extended_attribute[:name])
        extended_attribute[:id] = existing_attribute.try(:id) 
      end
      
      success = ticket.update_attributes( ticket_attributes )
      # log the success
      if success             
        results[:updated_tickets] << ticket
        results[:messages] << "Ticket Updated: Ticket #{ unique_key} was successfully updated."
      else
        results[:invalid_ticket_data] << ticket_attributes
        results[:messages] << "Ticket Update Failed:  Ticket #{ unique_key} could not be updated: #{ticket.errors.full_messages.to_sentence})."
      end
    end
    return results
  end
  
  # helper method to create a ticket from row data or report failures
  def self.create_ticket_with_row_data( ticket_attributes, plan, results )
    # cache the unique key
    unique_key = ticket_attributes[:foreign_id]    
    # try to create the ticket
    ticket = plan.tickets.create( ticket_attributes )
    # log the success
    if ticket.valid?             
      results[:created_tickets] << ticket
      results[:messages] << "Ticket Created Ticket #{ unique_key} was successfully updated."
    else
      results[:invalid_ticket_data] << ticket_attributes
      results[:messages] << "Ticket Create Failed:  Ticket #{ unique_key} could not be updated: #{ticket.errors.full_messages.to_sentence})."
    end
    return results
  end
  
end
