################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# host_name:
#   name: IP address remote server
# user:
#   name: Login for remote server
# password:
#   name: Password for remote server
#   private: yes
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle
role :all, params["host_name"] # Must be set for Capistrano

# ==============  Build User Script Here ===============

cmd = "ls -l /mnt/.ss/servers"
# Run the command on the server
results = run_command(params, cmd, "")

# Test the results for success or failure
success = "server_8080"
if results.include?(success)
  write_to "Success test, looking for #{success}: Success (term found)"
else
  write_to "Success test, looking for #{success}: Command_Failed"
end

# Close the output file
@hand.close
