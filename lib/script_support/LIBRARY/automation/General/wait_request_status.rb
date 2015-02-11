# -------------------- wait_request_status --------------------#

###
# target_request_id:
#   description: ID of a specific request
# target_status:
#   description: status which indicates success
#   type: in-list-single
#   list_pairs: created,Created|planned,Planned|started,Started|problem,Problem|hold,Hold|complete,Complete
###

# Instructions:
# This script will wait up till max_time for another request to complete
# it will check every checking_interval to verify status
# if the request has not completed by max_time it will throw a problem

params["direct_execute"] = true
# -------------------- Set Variables --------------------#
token="7e3041ebc2fc05a40c60028e2c4901a"  # -- Use your token from the User Profile screen
base_url = "REST/requests" #  Leave this alone
target_status = params["target_status"].downcase
max_time = 15*60 # seconds = 15 minutes
checking_interval = 15 #seconds
req_id = params["target_request_id"].length < 2 ? params["last_created_request"] : params["target_request_id"]

# -------------------- Script Body --------------------#
if req_id.to_i > 0 && ["created","planned","started","problem","hold","complete"].include?(target_status)
  routine_part = "/request_status?token=#{token}"
  reg = /\<status\>.+\</
  rest_url = "#{base_url}/#{req_id}#{routine_part}"
  write_to "REST Call: #{rest_url}"
  rest_result = fetch_url(rest_url)
  write_to "#-------------- Request Response -----------------#"
  write_to rest_result
  # Test the results for success or failure
    success = "App:"
    unless rest_result.include?(success)
      req_status = "none"
      start_time = Time.now
      elapsed = 0
      until (elapsed > max_time || req_status == target_status)
        rest_result = fetch_url(rest_url)
        found = rest_result.scan(reg)
        unless found.empty?
          req_status = found[0].gsub("<status>","").gsub("<","").downcase
        else
          elapsed = max_time + 1
        end
        write_to "Waiting(#{elapsed.floor.to_s}) - Current status: #{req_status}"
        sleep(checking_interval)
        elapsed = Time.now - start_time
      end
      if req_status == target_status
        write_to "Success test, looking for #{success}: Success!"
      else
        write_to "Command_Failed: Max time: #{max_time}(secs) reached.  Status is: #{req_status}, looking for: #{target_status}"
      end
    else
      write_to "Success test, looking for #{success}: Command_Failed"
    end
else
  write_to "Command_Failed: No Request_id specified"  
end
