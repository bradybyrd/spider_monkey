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
#   name: Login for remote server (sudo access)
# password:
#   name: Password for remote server
#   private: yes
###

# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
params["sudo"] = "yes"
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

#set the role on the server
role :all, params["host_name"]

cmd = "/etc/init.d/httpd restart"
# Run the command on the server
results = run_command(params, cmd, "")

# Test the results for success or failure
success = "chown deploy:deploy"
unless results.include?("[  OK  ]")
  write_to "Success test, looking for #{success}: Success"
else
  write_to "Success test, looking for #{success}: Command_Failed (term not found)"
end

# Close the output file
@hand.close
