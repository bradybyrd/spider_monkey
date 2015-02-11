################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

#  Create Script arguments in the comment block below.  Script arguments must have
###
# user:
#   name: Login for remote server
# password:
#   name: Password for remote server
#   private: yes
# deploy_dir:
#   name: target directory to copy the package
# setup_script:
#   name: Script to run from deploy package
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle
#set the role on the server
#  Disable for this example -role :all, params["servers"]

#====================  User Portion of Script ==========================#

# Get a list of the servers and properties
# Auth must be ssh, public key or username/pwd same on all target servers
# List is [server_name, {property1=>value1, propery2=>value2 }]

hosts = []
servers = get_server_list(params)
servers.each do |server|
  server[1].each do |prop, val|
    #write_to "  #{prop}=#{val}"
    if prop.downcase.include?("bladelogic_server_name")  #Only get the blade servers
      hosts << server[0] if val.length > 4 # assume all server names are longer than 4 (none is default)
    end
  end
end
write_to "Executing on Hosts: #{hosts.inspect}"
role :all do # This tells Capistrano to perform the action on an array of hosts
 hosts
end


set :user, params["user"]
set :password, params["password"]

# Now Run the Command
setup_script = params["setup_script"]
# Note - in multiple servers, prepending the hostname lets you know which server gave which results
command = "echo 'Running on server: ';hostname; ruby #{params["deploy_dir"]}/#{setup_script}"
write_to "Running Setup Script #{setup_script}..."
write_to "  From: #{params["deploy_dir"]}"
results = run_command(params, command, '', true)
write_to results

# Test the results for success or failure
success = "files copied successfully"
# Test the results for success or failure
write_to "==========  Success Test ==========="
write_to "Testing results on #{hosts.size.to_s} servers, looking for that many instances of the success term"
found_instances = results.scan(success).size
if found_instances == hosts.size
  write_to "Success - found: #{found_instances} of #{success} in results"
else
  write_to "Command_Failed - found: #{found_instances} of #{success} in results"
end

# Close the output file
@hand.close
