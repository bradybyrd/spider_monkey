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
# package_source:
#   name: local directory to find the package
# deploy_dir:
#   name: target directory to copy the package
# recent_file_property:
#   name: Property that holds the package name
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle
#set the role on the server
#  Disable for this example -role :all, params["servers"]

#====================  User Portion of Script ==========================#

package_file = params[params["recent_file_property"]]
unless package_file.nil? || package_file.length < 2
  # Get a list of the servers and properties
  # Auth must be ssh, public key or username/pwd same on all target servers
  # List is [server_name, {property1=>value1, propery2=>value2 }]
  # Example
  hosts = []
  servers = get_server_list(params)
  servers.each do |server|
    hosts << server[0]  #Grab the Server Name and make the host array
  end
  write_to "Executing on Hosts: #{hosts.inspect}"
  role :all do # This tells Capistrano to perform the action on an array of hosts
    hosts
  end


  set :user, params["user"]
  set :password, params["password"]

  # Now Run the Command
  #results = run_command(params, params["command"], "")
  local_path = params["package_source"]
  shared_path = params["deploy_dir"]
  pkg = package_file
  write_to "Uploading Files..."
  write_to "  From: #{local_path}/#{pkg} To: #{shared_path}"
  upload("#{local_path}/#{pkg}", "#{shared_path}", :via => :scp)
  results = ""
else
  results = "Command_Failed - No package file specified"
end
# Test the results for success or failure
success = ""
unless results.include?(success)
  write_to "Success test, looking for #{success}: Command_Failed (term not found)"
else
  write_to "Success test, looking for #{success}: Success "
end

# Close the output file
@hand.close
