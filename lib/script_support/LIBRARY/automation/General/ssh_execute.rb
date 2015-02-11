################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# hosts:
#   name: IP address remote server
# user:
#   name: Login for remote server
# password:
#   name: Password for remote server
#   private: yes
# command:
#   name: Name of command
# sudo:
#   name: Use sudo? (yes or no/blank)
# arguments:
#   name: Arguments to script
# success_string:
#   name: String to look for in the results
# ignore_exit_codes:
#   description: Ignore exit codes
#   type: in-list-single
#   list_pairs: false,no|true,yes
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

#set the role on the server
role :all, params["hosts"]

# Run the command on the server
results = run_command(params, params["command"], params["arguments"])

# Test the results for success or failure
success = params["success_string"]
unless results.include?(success)
  write_to "Success test, looking for #{success}: Command_Failed"
else
  write_to "Success test, looking for #{success}: Success (term found)"
end

# Close the output file
@hand.close
