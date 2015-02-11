################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ServiceNow
  class Requester
    
    cattr_accessor :Keys, :Tables
    
    def self.Keys
      return [ "getKeys", "get", "insert", "update", "deleteMultiple", "deleteRecord", "getRecords" ]
    end
    
    def self.Tables 
      return [ "change_request", "cmdb_ci_computers", "task", 
                "u_environment", "u_assignment_group", "u_pmo_project_id",
                "cmdb_ci"
              ]
    end
    
  end  
end
