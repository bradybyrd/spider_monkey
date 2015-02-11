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
# source_path:
#   name: path to source directory
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

#==============  User Portion of Script ==================

#set the role on the server
role :all, params["hosts"]

# Run the command on the server
cmd = "cd #{params["source_path"]}; ./build_package.rb y"
results = run_command(params, cmd, "")

# Test the results for success or failure
success = "Package Version:"
unless results.include?(success)
  write_to "Success test, looking for #{success}: Command_Failed"
else
  write_to "Success test, looking for #{success}: Success (term found)"
end

# Close the output file
@hand.close
