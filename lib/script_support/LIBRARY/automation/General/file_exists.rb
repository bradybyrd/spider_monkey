################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# File Exists - scans for a file BJB - 9-21-10 #
###
# hosts:
#   name: IP address remote server
# user:
#   name: Login for remote server
# password:
#   name: Password for remote server
#   private: yes
# directory:
#   name: path to check
# sudo:
#   name: Use sudo? (yes or no/blank)
# file_to_find:
#   name: filename or filter (*.txt)
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle
# ========================================================================
# User Script
# ========================================================================

#set the role on the server
role :all, params["hosts"]

is_filter = false
dir = params["directory"]
file_to_find = params["file_to_find"]
is_filter = true if file_to_find.include?("*")

# Run the command on the server
cmd = "ls -l #{dir}/#{is_filter ? file_to_find : "" }"
results = run_command(params, cmd, '', true)

# Test the results for success or failure
success = "Failure 500"
if is_filter
  write_to results.length > 5 ? "Success - found #{file_to_find}" : "Command_Failed - no results from #{file_to_find}"
else
  write_to results.include?(file_to_find) > 5 ? "Success - found #{file_to_find}" : "Command_Failed - file not found: #{file_to_find}"
end

# Close the output file
@hand.close
