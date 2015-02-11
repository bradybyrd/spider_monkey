################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# command:
#   name: Name of command
# success:
#   name: Term or Phrase to indicate success
###
# Flag the script for direct execution
params["direct_execute"] = true

#==============  User Portion of Script ==================

# Run the command directly on the localhost
result = run_command(params, params["command"], '')

# Apply success or failure criteria
if result.index(params["success"]).nil?
  write_to "Command_Failed - term not found: [#{params["success"]}]\n"
else
  write_to "Success - found term: #{params["success"]}\n"
end
