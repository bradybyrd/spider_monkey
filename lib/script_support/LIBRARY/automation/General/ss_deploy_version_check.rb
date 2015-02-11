################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# ss_deploy_version_check
# BJB 1-3-11 Streamstep, Inc.
###
###
# Load the input parameters file and parse as yaml
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

#==============  User Portion of Script ==================
unless params["temp Server"].nil?
  hosts = [params["temp Server"]]
  write_to "Executing on Hosts: #{hosts.inspect}"
  role :all do # This tells Capistrano to perform the action on an array of hosts
    hosts
  end

  params["user"] = params["Deploy User"]
  params["password"] = params["Deploy pwd"]
  cmd = "ruby #{params["SS_script_support_path"]}/LIBRARY/streamstep_version_checker.rb"
  result = run_command(params, cmd, "")
  # Apply success or failure criteria
  success = "patchlevel"
  if result.index(success).nil?
    write_to "Command_Failed - term #{success} found\n"
  else
    write_to "Success - found term: #{success}\n"
  end
else
  write_to "Command_Failed: No server property specified"
end
#Close the file
@hand.close
