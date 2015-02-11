################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# build_host:
#   name: IP address remote server
# ara_config_file:
#   name: Name of xml config file
# build_path:
#   name: directory for builds
###
# Load the input parameters file and parse as yaml.

#set the role on the server
role :all, params["build_host"]
params["user"] = "deploy"
ara_config = "#{params["build_path"]}/ara_config/#{params["ara_config_file"]}"
cmd = "cat #{ara_config}"
# Run the command on the server
results = run_command(params, cmd, "")

# Test the results for success or failure
success = "Phurnace xmlns"
unless results.include?(success)
  write_to "Success test, looking for #{success}: Command_Failed"
else
  write_to "Success test, looking for #{success}: Success"
  fil_name = "#{params["SS_output_dir"]}/#{params["ara_config_file"]}"
  write_to "=========== Phurnace Configuration ==========\n"
  write_to "Downloading Files..."
  write_to "  From: #{ara_config} To: #{fil_name}"
  # download (also upload) is a capistrano function that uses the existing ssh channel for scp copy
  download("#{ara_config}", "#{fil_name}", :via => :scp)
  
  ipos = params["SS_output_dir"].index("automation_results")
  write_to "#{params["SS_base_url"]}/#{params["SS_output_dir"].slice((ipos + 7)..(ipos + 200))}/#{params["ara_config_file"]}"
  
end
