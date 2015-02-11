################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# deploy_check_package - scans for a file set in a previous step BJB - 9-21-10 #
###
# user:
#   name: Login for remote server(s)
# password:
#   name: Password for remote server(s)
#   private: yes
# directory:
#   name: path to check
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle
# ========================================================================
# User Script
# ========================================================================

# Get a list of the servers and properties
# Auth must be ssh, public key or username/pwd same on all target servers
# List is [server_name, {property1=>value1, propery2=>value2 }]
hosts = []
servers = get_server_list(params)
servers.each do |server|
  server[1].each do |prop, val|
    #write_to "  #{prop}=#{val}"
    if prop.downcase.include?("bladelogic_server_name")  #Only get the blade servers
      hosts << server[0] if val.length > 6 # assume all server names are longer than 4 (none is default)
    end
  end
end
write_to "Executing on Hosts: #{hosts.inspect}"
role :all do # This tells Capistrano to perform the action on an array of hosts
  hosts
end

package_file = params[params["recent_file_property"]]
unless package_file.nil? || package_file.length < 2
  dir = "#{params["directory"]}/builds"

  # Run the command on the server
  write_to "======= Listing build directory on app servers ======="
  # Note - in multiple servers, prepending the hostname lets you know which server gave which results
  cmd = "echo 'Running on server: ';hostname; ls -l #{dir}"
  results = run_command(params, cmd, '',true)
  write_to results
  # Test the results for success or failure
  write_to "==========  Success Test ==========="
  write_to "Testing results on #{hosts.size.to_s} servers, looking for that many instances of the success term"
  found_instances = results.scan(package_file).size
  if found_instances == hosts.size
    write_to "Success - found: #{found_instances} of #{package_file} in results"
  else
    write_to "Command_Failed - found: #{found_instances} of #{package_file} in results"
  end
else
  write_to "Command_Failed - No package file property set"
end

# Close the output file
@hand.close
