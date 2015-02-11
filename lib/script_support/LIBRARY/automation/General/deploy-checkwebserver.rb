################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# SmartRelease Scripting Framework - v.2.1.1 <<= Important, do no delete

#  Create Script arguments in the comment block below.  Script arguments must have
###
# success:
#   name: text to look for in the webpage
# page_to_test:
#   name: page on the site to test (relative to base url)
###
# Load the input parameters file and parse as yaml.
#set the role on the server
#  Disable for this example -role :all, params["servers"]

#====================  User Portion of Script ==========================#

  # Get a list of the servers and properties
  # Auth must be ssh, public key or username/pwd same on all target servers
  # List is [server_name, {property1=>value1, propery2=>value2 }]
  # Example
  hosts = []
  ports = {}
  servers = get_server_list(params)
  servers.each do |server|
    hosts << server[0]  #Grab the Server Name and make the host array
  end

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
    cur_result = run_command(params, command, "")
    # Test the results for success or failure
    success = "Version: #{params["ref Web Version"]}"
    unless cur_result.include?(success)
      results += "Success test, looking for #{success}: Command_Failed (term not found)\n"
    else
      results += "Success test, looking for #{success}: Success \n"
    end
    results += cur_result
  end 
  write_to results
