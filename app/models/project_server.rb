################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'automation_common'
class ProjectServer < ActiveRecord::Base
  include FilterExt

  has_many :queries
  has_many :projects, :class_name => "IntegrationProject"
  has_many :parent_projects, :class_name => "IntegrationProject", :conditions => {:parent_id => nil}
  has_many :releases, :through => :projects  
  has_many :tickets, :dependent => :nullify # Clear out integration id in tickets, deleting tickets would result in a big data loss for the user
  has_many :plans, :dependent => :nullify
  
  has_many :scripts, :foreign_key => 'integration_id', :dependent => :nullify

  has_one :application_component_mapping
  
  # TODO - Put them in database? Make this dynamic such that even API will be build dynamically if possible.
  SERVER = { "Rally" => 1, "Jira" => 2, "Mantis" => 3, "ServiceNow" => 4, "Hudson/Jenkins" => 5, "General" => 6, 
             "Streamstep" => 7, "Remedy via AO" => 8, "BMC Application Automation" => 9, "RLM Deployment Engine" => 10} 
  # More TODO - add , "Bladelogic" => 7  and allow bladelogic scripts to reference different servers
  
  
  validates :server_name_id,:presence => true
  validates :name,:presence => true
  validates :server_url,:presence => true
  validates :username,:presence => true #, :password
  validates :ip,:format => { :with => /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/i, :allow_blank => true}
  #validates_format_of :server_url, :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix
  #validates_format_of :server_url, :with => /^(http|ftp|https?):\/\//
  validates :port, :numericality => { :if => Proc.new { |ps| ps.server_name_id.eql?(2) }}
  
  scope :active, where(:is_active => true)
  scope :inactive, where(:is_active => false)
  scope :filter_by_name, lambda { |filter_value| where("LOWER(project_servers.name) like ?", filter_value.downcase) }
  scope :ticketing_systems, where('project_servers.server_name_id IN (?)', [1, 2, 3, 4, 8]).order('name')
  
  # scope to find Project Servers that have ticket getting resource automations
  # a necessary hack because oracle will not support 'uniq' with a CLOB field
  # so we get the ids and then get the whole objects https://github.com/rsim/oracle-enhanced/issues/112
  scope :ids_with_ticketing_automations, joins(:scripts).select('project_servers.id').where('scripts.maps_to' => 'Ticket', 'scripts.automation_type' => 'ResourceAutomation').uniq

  attr_accessible :server_name_id, :name, :ip, :server_url, :port, :username, :password, :details

  # project servers may be filtered through REST or the UI
  is_filtered cumulative: [:name], boolean_flags: {default: :active, opposite: :inactive}

  def server_type
    ProjectServer::SERVER.key(server_name_id)
  end

  class << self
    
    def rally
      ProjectServer.where(:server_name_id => 1) # 1 is for Rally, See ProjectServer::SERVER
    end
    
    def mantis
      ProjectServer.where(:server_name_id => 3) # 3 is for Mantis, See ProjectServer::SERVER
    end
    
    def service_now
      ProjectServer.where(:server_name_id => 4) # 4 is for ServiceNow, See ProjectServer::SERVER
    end
    
    def hudson
      ProjectServer.where(:server_name_id => 5) # 5 is for Hudson, See ProjectServer::SERVER
    end

    def streamstep
      ProjectServer.where(:server_name_id => 7) # 7 is for Streamstep, See ProjectServer::SERVER
    end
    
    def remedy_via_ao
      ProjectServer.where(:server_name_id => 8) # 8 is for Remedy via AO, See ProjectServer::SERVER
    end

    def bmc_application_automation
      ProjectServer.where(:server_name_id => 9) #9 is for BMC Application Automation, See ProjectServer::SERVER
    end

    def rlm_deployment_engine
      ProjectServer.where(:server_name_id => 10) #10 is for RLM Deployment Engine, See ProjectServer::SERVER
    end
    
    def select_list(integration_type)
      case integration_type
      when 'mantis'
          result = ProjectServer.active.where(:server_name_id => 3) 
      when 'rally'
          result = ProjectServer.active.where(:server_name_id => 1) 
      when 'service_now'
          result = ProjectServer.active.where(:server_name_id => 4)
      when 'hudson/jenkins', 'hudson'
          result = ProjectServer.active.where(:server_name_id => 5) 
      when 'general'
          result = ProjectServer.active.where(:server_name_id => [6,3,7,2,8]) 
      when 'streamstep'
          result = ProjectServer.active.where(:server_name_id => 7)
      when 'remedy_via_ao'
          result = ProjectServer.active.where(:server_name_id => 8)
      when 'bmc_application_automation'
          result = ProjectServer.active.where(:server_name_id => 9)
      when 'rlm_deployment_engine'
          result = ProjectServer.active.where(:server_name_id => 10)
      else
          result = ProjectServer.active
      end
      result.collect{|ps| [ps.name, ps.id]}
    end
    
  end
  
  def is_sn_or_rally_server?
    is_of_rally? || is_of_service_now?
  end
  
  def is_of_rally?
    server_name_id == 1
  end
  
  def is_of_service_now?
    server_name_id == 4
  end
  
  def server_type
    SERVER.invert[server_name_id]
  end
    
  def streamstep_integration_info
    info = {
      :server_url => server_url,
      :username => username,     
      :password => password,
      :token => extract_token
    }
  end
  
  def extract_token
    reg = /token: /
    found = details.scan(reg)
    if found.size < 1 
      return "No Token Found"
    else
      return found[0].chomp.gsub("token: ","")
    end
  end
      
  def cache_exists?
     File.exist? "#{RAILS_ROOT}/tmp/cache/views/project_tree_#{id}.cache"
  end
  
  def activate!
    self.update_attribute(:is_active, true)
  end
  
  def deactivate!
    self.update_attribute(:is_active, false)
  end
  
  def build_integration_script_header(mask=false)
    prefix = integration_header_prefix
    script_text = "\n#=== #{server_type} Integration Server: #{name} ===#"
    script_text += "\n# [integration_id=#{id.to_s}]"
    dns = port.nil? ? server_url : replace_port(server_url, port)
    script_text += "\n#{prefix}dns = \"#{dns}\""
    script_text += "\n#{prefix}username = \"#{username}\""
    script_text += "\n#{prefix}password = \"#{mask ? "-private-" : password}\""
    script_text += "\n#{prefix}details = \"#{details}\""
    script_text += "\n#{prefix}password_enc = \"#{AutomationCommon::encrypt(password)}\""
    script_text += "\n#=== End ===#\n"
  end

  def add_update_integration_values(content, mask=false)
    id_reg = /\[integration_id=.+\]/
    reg = /\#\=\=\=.+\=\=\= End \=\=\=\#/m
    has_id = content.scan(id_reg)
    if (!has_id.empty?) && (content =~ reg)
      new_header = build_integration_script_header(mask)
      content = content.gsub(reg, new_header)
    else
      content_length = content.length
      ipos = content.index("###")
      header = build_integration_script_header(mask)
      if ipos
        ipos2 = content.slice((ipos+3)..content_length).index("###")
        if ipos2
          script = content.slice(0..(ipos+3+ipos2+3)) + header + content.slice((ipos+3+ipos2+4)..content_length);
          content = script
        else
          script = content.slice(0..(ipos+3)) + header + content.slice((ipos+4)..content_length);
          content = script
        end
      else
        content = header + content
      end
    end
    content
  end
  
  def integration_header_prefix(script_type = nil)
    s_type = script_type.nil? ? server_type : script_type
    case s_type
    when 'Hudson', 'Hudson/Jenkins'
      prefix = "SS_hudson_"
    when 'Bladelogic'
      prefix = "SS_bladelogic_"
    else
      prefix = "SS_integration_"
    end
  end

  private

  def replace_port(server_url, port)
    url = URI.parse(server_url)
    url.port = port
    url.to_s
  end

end
