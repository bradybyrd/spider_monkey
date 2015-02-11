################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ServiceNow
  class Response
    attr_accessor :key, :content
    attr_reader :parsed
    cattr_accessor :Attributes
    
    # These attributes will be defined by user under System > Integrations
    def self.Attributes 
      return [
                  "start_date", 
                  "end_date", 
                  "short_description",
                  "u_application",
                  "u_cc_environment",
                  "u_config_items_list",
                  "u_pmo_project_id",
                  "u_service_affecting",
                  "u_code_synch_required",
                  "state", 
                  "stage",
                  "category",
                  "approval",
                  "u_version_tag",
                  "assignment_group",
                  "risk",
                  "type",
                  "u_release_notes",
                  "u_streamstep_link"
                 ]
    end             
    # Using temporary model `Change Request` but later this will be dynamic too.
    
    def initialize(params = { })
      params.keys.each { |k| self.send("#{k}=".to_sym, params[k]) if self.respond_to?(k.to_sym) }
    end
    
    def parse!
      fil = File.open('log/snow.txt',"w+")
      fil.puts key
      fil.puts "#---------------------------#"
      fil.puts content
      fil.close
      @parsed = case key
        when "getKeys" 
          content.first.split(",")
        when "getRecords" 
          content
        when "insert" 
          content.first
      end
    end
    
  end
end
