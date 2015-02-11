################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# url_check:
#   name: URL to check
# success:
#   name: Term or Phrase to indicate success
###
# Load the input parameters file and parse as yaml
params = load_input_params(ENV["_SS_INPUTFILE"])

# Flag the script for direct execution
params["direct_execute"] = true

# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

# ========= Put User Script Items here =========#

cmd = "wget -qO- #{params["url_check"]} | grep '#{params["success"]}'"
# Run the command directly on the localhost
result = run_command(params, cmd, '')

write_to "Testing URL: #{params["url_check"]}"
# Apply success or failure criteria
ipos = result.index(params["success"])
if ipos.nil?
  write_to "Command_Failed - term not found: [#{params["success"]}]\n"
else
  write_to "Success - found term: #{params["success"]}\n"
  write_to "Test Result: #{result.slice(ipos..(ipos + 50))}"
end

#Close the file
@hand.close
