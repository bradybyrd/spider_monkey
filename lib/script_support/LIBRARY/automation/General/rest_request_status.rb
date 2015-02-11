################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# target_request_id:
#   description: ID of a specific request
# target_status:
#   description: status which indicates success
#   type: in-list-single
#   list_pairs: created,Created|planned,Planned|started,Started|problem,Problem|hold,Hold|complete,Complete
###

# Load the input parameters file and parse as yaml.
require 'rubygems'
require 'net/http'
require 'uri'
params["direct_execute"] = true

token="7e3041ebc2fc05a40c60028e2c4901a"
@ss_url = params["SS_base_url"] 

def fetch_url(path, testing=false)
  tmp = "#{@ss_url}/#{path}".gsub(" ", "%20") #.gsub("&", "&amp;")
  jobUri = URI.parse(tmp)
  puts "Fetching: #{jobUri}"
  request = Net::HTTP.get(jobUri) unless testing
end

# Pre URL stuff
base_url = "REST/requests"
task = "none"
req_id = params["target_request_id"]
status = params["target_status"]
if req_id.to_i > 0
  routine_part = "/request_status?token=#{token}"
  rest_url = "#{base_url}/#{req_id}#{routine_part}"
  write_to "REST Call: #{rest_url}"
  rest_result = fetch_url(rest_url)
  write_to "==== Request Response ===="
  write_to rest_result
  # Test the results for success or failure
    success = "App:"
    unless rest_result.include?(success)
      reg = /\<status\>.+\</
      found = rest_result.scan(reg)
      unless found.empty?
        req_status = found[0].gsub("<status>","").gsub("<","")
        if req_status == status
          write_to "Success test, looking for #{success}: Success!"
        else
          write_to "Command_Failed: Status is: #{req_status}, looking for: #{status}"
        end
      else
        write_to "Command_Failed: No status specified"
      end
    else
      write_to "Success test, looking for #{success}: Command_Failed"
    end
else
  write_to "Command_Failed: No Request_id specified"  
end
