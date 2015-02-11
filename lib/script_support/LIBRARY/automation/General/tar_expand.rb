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
# target_dir:
#   name: target directory for the archive
# archive_file:
#   name: archive name
# host:
#   name: Host dns or 'All' for all component servers
# sudo:
#   name: Use sudo? (yes or no/blank)
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle
#set the role on the server
#  Disable for this example -role :all, params["servers"]

#====================  User Portion of Script ==========================#

# Get a list of the servers and properties
# List is [server_name, {property1=>value1, propery2=>value2 }]
# Example
unless params["host"].nil? || params["host"] == ""
  if params["host"].downcase == "all" # Run on all hosts
    hosts = []
    servers = get_server_list(params)
    servers.each do |server|
      #write_to "Server: #{server[0]}"
      server[1].each do |prop, val|
        #write_to "  #{prop}=#{val}"
        hosts << val if prop.downcase.include?("dns")  #Grab the DNS property and make the host array
      end
    end
  else
    hosts = [params["host"]]
  end
  write_to "Executing on Hosts: #{hosts.inspect}"
  role :all do # This tells Capistrano to perform the action on an array of hosts
   hosts
  end
  # Be sensitive to gzip
  use_z = params["archive_file"].include?(".tgz") ? "z" : ""
  # Build Tar Command
  command = "usr/bin/tar -xf#{use_z} #{params["target_dir"]}/#{params["archive_file"]} > 1"
  # Now Run the Command
  results = run_command(params, command, "")

  # Test the results for success or failure
  success = "Failure 500"
  unless results.include?(success)
    write_to "Success test, looking for #{success}: Command_Failed"
  else
    write_to "Success test, looking for #{success}: Success (term found)"
  end
else
  write_to "Must specify a host or All"
end

# Close the output file
@hand.close
