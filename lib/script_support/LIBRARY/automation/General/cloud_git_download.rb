################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# hosts:
#   name: IP address remote server
# git_user:
#   name: Login for remote server
# password:
#   name: Password for remote server
#   private: yes
# repository:
#   name: Repository name user/repository/branch
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle
role :all, params["hosts"] # Must be set for Capistrano

# ==============  Build User Script Here ===============

client_name = params["New Client Name"]
if(client_name.length < 2 || client_name.nil?)
  write_to "Command_Failed - No Client Name set"
else
  params["user"] = params["git_user"]
  repos = params["repository"].split("/")
  if repos.size > 1
    branch = repos.size > 2 ? repos[2] : "master"
    # Works: /mnt/.ss/setup setup_git <client_name> streamstep/SmartRelease_2 stage_merge
    cmd = "/ss/.support/setup.rb setup_git #{client_name} #{repos[0]}/#{repos[1]} #{branch}"
    # Run the command on the server
    results = run_command(params, cmd, "")

    # Test the results for success or failure
    success = "chown -R deploy:deploy"
    if results.include?(success)
      write_to "Success test, looking for #{success}: Success"
    else
      write_to "Success test, looking for #{success}: Command_Failed (term not found)"
    end
  else
    write_to "Git repository needs: client/repository/branch"
  end
end
# Close the output file
@hand.close
