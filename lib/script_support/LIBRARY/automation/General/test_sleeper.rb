################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# Sleeper
# Routine waits the specified interval in seconds
# periodically doing things
###
# sleep_seconds:
#   name: Time to wait in seconds
###
# Load the input parameters file and parse as yaml
params = load_input_params(ENV["_SS_INPUTFILE"])
# Flag the script for direct execution
params["direct_execute"] = true
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

#==============  User Portion of Script ==================

# Run the command on the server
# Amazon Routines are in the script support directory
cmd = "ruby #{params["SS_script_support_path"]}/LIBRARY/sleeper.rb"
sleep_seconds = params["sleep_seconds"].nil? ? 240 : params["sleep_seconds"]
result = run_command(params, cmd, sleep_seconds)

# Apply success or failure criteria
success = "stopping execution"
if result.index(success).nil?
  write_to "Command_Failed - term not found: [#{success}]\n"
else
  write_to "Success - found term: #{success}\n"
end

#Close the file
@hand.close