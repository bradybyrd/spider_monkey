################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ProjectServer < ActiveRecord::Base
  
  SNOW_tables = { "u_environment" => "u_cc_environment",
    "u_pmo_project_id" => "u_pmo_project_id",
    "sys_user" => "sys_user",
    "sys_user_group" => "assignment_group",
    "cmdb_ci_server" => "cmdb_ci_server",
    "cmdb_ci_appl" => "u_application_name",
  }
  has_many :change_requests, :dependent => :destroy
  has_many :service_now_data, :class_name => "ServiceNowData", :dependent => :destroy
  
  # FIXME: Note, our index is now case insensitive, so this will hit the database with a bigger task when getting
  # these and sorting them by lower case.  Since databases differ in the syntax to add a case insensitive index,
  # and some don't offer it all outside of collation settings, I have opted to accept the performance hit rather than
  # risk a migration.  Out combo boxes are very odd behaving (typing first letter, etc) if we allow the default 
  # case sensitive sort to remain.
  has_many :service_now_apps, 
           :class_name => "ServiceNowData",
           :conditions => {"service_now_data.table_name" => "cmdb_ci_appl"},
           :order => "lower(service_now_data.name) ASC"
  
  has_many :service_now_environments, 
           :class_name => "ServiceNowData", 
           :conditions => {"service_now_data.table_name" => "u_environment"},
           :order => "lower(service_now_data.name) ASC"
  
  has_many :service_now_pmo_project_ids, 
           :class_name => "ServiceNowData",
           :conditions => {"service_now_data.table_name" => "u_pmo_project_id"},
            :order => "lower(service_now_data.name) ASC"
  
  has_many :service_now_users, 
           :class_name => "ServiceNowData",
           :conditions => {"service_now_data.table_name" => "sys_user"},
            :order => "lower(service_now_data.name) ASC"
           
  has_many :service_now_groups, 
           :class_name => "ServiceNowData",
           :conditions => {"service_now_data.table_name" => "sys_user_group"},
            :order => "lower(service_now_data.name) ASC"

  has_many :service_now_cis, 
           :class_name => "ServiceNowData",
           :conditions => {"service_now_data.table_name" => "cmdb_ci"},
           :order => "lower(service_now_data.name) ASC"

   has_many :service_now_servers, 
            :class_name => "ServiceNowData",
            :conditions => {"service_now_data.table_name" => "cmdb_ci_server"},
            :order => "lower(service_now_data.name) ASC"
                        
  ServiceNowStates = {
    "1" => "Open",
    "2" => "Work in Progress",
    "3" => "Closed Complete",
    "4" => "Closed Incomplete",
    "7" => "Closed Skipped", 
    "8" => "Cancelled",
    "-5" => "Pending"
  }
                      
  def fetch_service_now_data
    save_service_now_data
  end

  def service_now_url
    "#{server_url}#{port.nil? ? '' : ':' + port.to_s }"
  end
  
  def save_service_now_data
    SNOW_tables.keys.each do |table_name|
      element_name = snow_name_field_lookup(table_name)
      # FIXME,Manish,2012-02-15,need to remove dependency on curl and have 100% jruby code to do this logic.
      msg = "Retreiving data - #{table_name}"
      loading_message(msg)

      curl_cmd = "curl -k --user '#{username}:#{password}' '#{server_url}'/#{table_name}"

      base_path = "#{RAILS_ROOT}/public/automation_results"
      FileUtils.mkdir_p(base_path)

      xml_string = %x[#{curl_cmd}.do\?XML > "public/automation_results/snow_#{table_name}.xml"]

      # curl_cmd = "curl -k --user '#{username}:#{password}' '#{server_url}/#{table_name}.do\?XML' > public/automation_results/snow_#{table_name}.xml"
      # xml_string = %x[#{curl_cmd}]
      logger.info "SS__ Fetching ServiceNow: #{curl_cmd}\nResult: #{xml_string}"
      #raise Error, "curl command failed" if xml_string.blank?
    end
    import_service_now_data
  end
  
  def import_service_now_data(do_table = nil)
    (do_table.nil? ? SNOW_tables.keys : [do_table]).each do |table_name|
      element_name = snow_name_field_lookup(table_name)
      file_name = "public/automation_results/snow_#{table_name}.xml"
      seed_hash = { "tag_name" => table_name, "ps_id" => self.id, "name_fields" => { "sys_id" => "sys_id", element_name => "name" } }
      parser = Nokogiri::XML::SAX::Parser.new(ServiceNow::PostCallbacks.new(seed_hash))
      parser.parse_file(file_name)
      msg = "Processing - #{table_name}"
      logger.info "Importing table: #{msg}"
      loading_message(msg)
    end
  end 
  
  def self.save_snow_data_record(attrs_hash)
    # Called by the xml_callback class to create the record
    unless attrs_hash['name'].blank?
      attribute = ServiceNowData.find_or_create_by_sys_id_and_project_server_id(attrs_hash['sys_id'], attrs_hash['ps_id'])
      attribute.table_name = attrs_hash['tag_name']
      attribute.name =  attrs_hash['name']
      attribute.save
    end
  end
  
  def snow_name_field_lookup(table_name)
    result = case table_name
      when "u_environment" ; "u_name"
      when "u_pmo_project_id"; "u_project_name"
      else; "name"
    end
  end
  
  def ORIG_save_service_now_data
    [ "u_environment",
      "u_pmo_project_id",
      "sys_user",
      "sys_user_group",
      "cmdb_ci_server",
      "cmdb_ci_appl",
    ].each do |table_name|
      element_name = case table_name
        when "u_environment"; "u_name"
        when "u_pmo_project_id"; "u_project_name"
        else; "name"
      end
      # FIXME,Manish,2012-02-15,need to remove dependency on curl and have 100% jruby code to do this logic.
      curl_cmd = "curl -k --user '#{username}:#{password}' '#{server_url}'/#{table_name}"
      xml_string = %x[#{curl_cmd}.do\?XML]
      logger.info "SS__ Fetching ServiceNow: #{curl_cmd}"
      raise Error, "curl command failed" if xml_string.blank?
      Nokogiri::XML(xml_string).xpath("//#{table_name}").map do |elem|
        name = elem.xpath("#{element_name}").inner_text
        sys_id = elem.xpath("sys_id").inner_text
        attribute = ServiceNowData.find_or_create_by_sys_id_and_project_server_id(sys_id, id)
        attribute.table_name = table_name
        attribute.name = name.blank? ? nil : name
        attribute.save
      end
    end
  end                      
 
end
