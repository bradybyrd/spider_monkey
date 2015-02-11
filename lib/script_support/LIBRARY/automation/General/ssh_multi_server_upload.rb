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
# host:
#   name: Host dns or 'All' for all component servers
# package_source:
#   name: local directory to find the package
# staging_dir:
#   name: target directory to copy the package
# package_file:
#   name: filename
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
# Example
unless params["host"].nil? || params["host"] == ""
  if params["host"].downcase == "all" # Run on all hosts
    hosts = []
    servers = get_server_list(params)
    servers.each do |server|
      server[1].each do |prop, val|
        hosts << val if prop.downcase.include?("dns")  #Grab the DNS property and make the host array
      end
    end
    write_to "Executing on Hosts: #{hosts.inspect}"
    role :all do # This tells Capistrano to perform the action on an array of hosts
     hosts
    end
  else
    hosts = [params["host"]]
  end
  

  set :user, params["user"]
  set :password, params["password"]

  # Now Run the Command
  #results = run_command(params, params["command"], "")
  local_path = params["package_source"]
  shared_path = params["staging_dir"]
  pkg = params["package_file"]
  write_to "Uploading Files..."
  write_to "  From: #{local_path}/#{pkg} To: #{shared_path}"
  upload("#{local_path}/#{pkg}", "#{shared_path}", :via => :scp)

  # Dummy the results
  results = "Everything worked fine, I promise"

  # Test the results for success or failure
  failure = "Failure 500"
  if results.include?(failure)
    write_to "Success test, looking for #{failure}: Command_Failed"
  else
    write_to "Success test, looking for #{failure}: Success (term found)"
  end
else
  write_to "Must specify a host or All"
end

# Close the output file
@hand.close
