#------- launch_request_or_template --------#
###
# request_template:
#   description: Name of request template
# request_id:
#   description: ID of a specific request
# target_environment:
#   description: optional environment for create request
# target_stage:
#   description: optional add new request to a plan and stage 
###
params["direct_execute"] = true

# ----------- launch_request_or_template ---------------------#
# Instructions:
# This script will launch another template or request in BRPM
# If the template is entered it will use it, otherwise the request_id
# If the target_environment is passed the routine will set the 
# environment of the created request

# -------------------- Set Variables --------------------#
token="7e3041ebc2fc05a40c60028e2c4901a"  # -- Use your token from the User Profile screen
base_url = "REST/requests" #  Leave this alone
task = "none"
req_id = params["request_id"]
template_name = params["request_template"]
target_env = params["target_environment"]
stage = params["target_stage"]

do_plan = (stage.length > 1 && params["request_plan"].length > 2)
  

if req_id.to_i > 0
  task = template_name.length > 1 ? "template" : "id"
else
  task = "template" if template_name.length > 1
end
case task
when "template"
  routine_part = "/create_request_from_template?token=#{token}&"
  rest_url = "#{base_url}#{routine_part}request_template=#{template_name}"
  rest_url += "&auto_start=yes"
  rest_url += "&plan=#{params["request_plan"]}&plan_stage=#{stage}" if do_plan
  rest_url += "&environment=#{target_env}" if target_env.length > 1
  write_to "REST Call: #{rest_url}"
  rest_result = fetch_url(rest_url)
  write_to "#------------ New Request Response ---------------#"
  write_to rest_result
when "id"
  routine_part = "/update_state?token=#{token}&"
  rest_url = "#{base_url}/#{req_id}#{routine_part}transition=start"
  write_to "REST Call: #{rest_url}"
  rest_result = fetch_url(rest_url)
  write_to "#------------ Request Response ---------------#"
  write_to rest_result
  
end
reg = /\<request_id\>.*\<\/request_id\>/
ans = rest_result.scan(reg)
if ans.empty?
  set_property_flag("last_created_request", "failed-no-request_id")  
else
  new_request = ans[0].gsub("<request_id>","").gsub("</request_id>","").strip
  set_property_flag("last_created_request", new_request)
end
# Test the results for success or failure
success = "request_id"
unless results.include?(success)
  write_to "Success test, looking for #{success}: Success!"
else
  write_to "Success test, looking for #{success}: Command_Failed"
end
