################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

#  Create Script arguments in the comment block below.  Script arguments must have
###
# success:
#   name: text to look for in the webpage
# page_to_test:
#   name: page on the site to test (relative to base url)
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
params["direct_execute"] = true
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle
#set the role on the server
#  Disable for this example -role :all, params["servers"]

#====================  User Portion of Script ==========================#

  # The list of servers is in the input file
hosts = []
ports = {}
servers = get_server_list(params)
servers.each do |server|
  hosts << server[0]  #Grab the Server Name and make the host array
end
if servers.size > 0
  port = nil
  page = params["page_to_test"]
  success = params["success"]
  # ##### BJB    Look here for alternate ports
  results = "Testing for version change on websites\n"
  # Build wget Command
  hosts.each do |host|
    results += "------ Server: #{host} --------\n"
    port = servers[host]["web_port"]
    if (port.nil? || port == "80" || port == "")
      port = ""
    else
      port = ":" + port
    end
    puts "Using port: #{port}"
    command = "wget -qO- http://#{host}#{port}/#{page}"
    # Now Run the Command
    cur_result = run_command(params, command, "", true)
    # Test the results for success or failure
    success = "Version:"
    unless cur_result.include?(success)
      results += "Success test, looking for #{success}: Command_Failed (term not found)\n"
    else
      results += "Success test, looking for #{success}: Success \n"
    end
    results += "<pre>" + cur_result + "</pre>"
  end 
  write_to results
else
  write_to "Command_Failed - No servers set (property: temp Hosts)"
end

# Close the output file
@hand.close
