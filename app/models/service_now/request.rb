################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ServiceNow
  class Request 
    
    attr_accessor :table, :key, :value, :project_server_id
    attr_reader :builder, :driver, :response
    
    class << self
      def search(params)
        args = {
          :value => params[:value], 
          :project_server_id => params[:project_server_id],
          :table => params[:table] || "change_request",
          :key => params[:key] 
        }
        search = ServiceNow::Request.new(args)
        search.query!
        response = search.response
        response.parse!
      end
      
      # Returns sys_id of change_request created
      def save(params = { })
        change_request = ServiceNow::ChangeRequest.new(:project_server_id => params[:project_server_id])
        # attrs should contain keys from ServiceNow::Response::Attributes
        change_request.attrs = params.delete_if{|k,v| k == :project_server_id}.stringify_keys
        change_request.operation = params[:operation] || "insert" 
        change_request.operation == "deleteRecord" ? change_request.delete! :  change_request.submit!
      end
      alias :delete :save
       
    end
    
    def initialize(params = { })
      params.keys.each { |k| self.send("#{k}=".to_sym, params[k]) if self.respond_to?(k.to_sym) }
    end
    
    def insert!(params)
      init_driver!
      @driver.add_method(key, "short_description")
      @response = ServiceNow::Response.new :content => @driver.call(key, params["short_description"]), :key => key
    end
    
    def query!
      validate(:key)
      validate(:table)
      return request!
    end

    def request!
      init_driver!
      @driver.add_method(key, "__encoded_query")
      @response = ServiceNow::Response.new :content => @driver.call(key, value), :key => key
    end
    
    def validate(what)
      case what
        when :key then validate_key
        when :table then validate_table
      end
    end
    
    def to_xml
      builder.to_xml if builder
    end
    
    protected
    
    def init_driver!
      @driver = SOAP::RPC::Driver.new(full_url, "cmdb")
      @driver.options["protocol.http.basic_auth"] << [full_url, user, password]
    end
    
    def project_server
      @project_server = ProjectServer.find(project_server_id) 
    end
    
    def base_url
      project_server
      @project_server.server_url
    end
    
    def full_url
      "#{base_url}/#{table}.do?SOAP" 
    end
    
    def user
      @project_server.username
    end
    
    def password
      @project_server.password
    end
    
    def validate_key
      set_default_key if key.blank?
      ServiceNow::Requester.Keys.include?(key)
    end
    
    def validate_table
      set_default_table if table.blank?
      ServiceNow::Requester.Tables.include?(table)
    end
    
    def set_default_table
      self.table = ServiceNow::Requester.Tables.first
    end
    
    def set_default_key
      self.key = "getRecords"
    end

  end  
end
