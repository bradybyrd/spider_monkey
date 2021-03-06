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
# source_dir:
#   name: path to code directory
# branch:
#   name: Name of branch
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

#==============  User Portion of Script ==================

#set the role on the server
role :all, params["hosts"]

#cmd = "/home/streamadmin/update_git.rb #{params["source_dir"]} #{params["branch"]}"
cmd = "cd #{params["source_dir"]}; git pull origin #{params["branch"]}"
# Run the command on the server
results = run_command(params, cmd, "")

# Test the results for success or failure
success = "STDOUT: Updating"
success2 = "Already up-to-date."
if results.include?(success) || results.include?(success2)
  write_to "Success test, looking for #{success}: Success (term found)"
else
  write_to "Success test, looking for #{success}: Command_Failed (term not found)"
end

# Close the output file
@hand.close
