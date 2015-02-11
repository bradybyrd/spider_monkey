################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# ss_deploy_setup_source
#  Pull application from source and setups up links
# BJB 1-3-11 Streamstep, Inc.
###
# instance_name:
#   name: Application deploy directory
# repository:
#   name: Repository name user/repository/branch
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
  client_name = params["Instance Name"]
  repos = params["repository"].split("/")
  if repos.size > 1
    branch = repos.size > 2 ? repos[2] : "master"
    # Works: /mnt/.ss/setup setup_git <client_name> streamstep/SmartRelease_2 stage_merge
    cmd = "ruby /home/deploy/provision/setup.rb setup_git #{client_name} #{repos[0]}/#{repos[1]} #{branch}"
    # Run the command on the server
    results = run_command(params, cmd, "")

    # Test the results for success or failure
    success = "rvmrc"
    if results.include?(success)
      write_to "Success test, looking for #{success}: Success"
    else
      write_to "Success test, looking for #{success}: Command_Failed (term not found)"
    end
  else
    write_to "Command_Failed: Git repository needs: client/repository/branch"
  end
else
  write_to "Command_Failed: No Server property specified"
end
