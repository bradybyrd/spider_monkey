################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# instance_name:
#   name: Application deploy directory
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

# ==============  Build User Script Here ===============

unless params["temp Server"].nil?
  hosts = [params["temp Server"]]
  write_to "Executing on Hosts: #{hosts.inspect}"
  role :all do # This tells Capistrano to perform the action on an array of hosts
    hosts
  end

  params["user"] = params["Deploy User"]
  params["password"] = params["Deploy pwd"]

  client_name = params["Instance Name"]
  if(client_name.length < 2 || client_name.nil?)
    write_to "Command_Failed - No Client Name set"
  else
    # Works: /mnt/.ss/setup setup_database <client_name>
    # Takes 10 mins!
    cmd = "ruby /home/deploy/provision/setup.rb setup_database #{client_name}"
    # Run the command on the server
    results = run_command(params, cmd, "")

    # Test the results for success or failure
    success = "Enabling requests..."
    if results.include?(success)
      write_to "Success test, looking for #{success}: Success"
    else
      write_to "Success test, looking for #{success}: Command_Failed (term not found)"
    end
  end
else
  write_to "Command_Failed no server present"
end
# Close the output file
@hand.close
