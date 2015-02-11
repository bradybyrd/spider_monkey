################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# server_profile:
#   name: Name of server profile
# ara_server:
#   name: ARA Server DNS
###
require 'fileutils'

#====================  User Portion of Script ==========================#

#=== SSH Integration Server: ARA ===#
# [integration_id=7]
SS_integration_dns = "ec2-184-73-150-83.compute-1.amazonaws.com"
SS_integration_username = "deploy"
SS_integration_password = "-private-"
#=== End ===#

hosts = [SS_integration_dns]
params["user"] = SS_integration_username
#params["password"] = SS_integration_password

write_to "Executing on Hosts: #{hosts.inspect}"
role :all do # This tells Capistrano to perform the action on an array of hosts
 hosts
end
# Build the Phurnace CLI command
#./runDeliver.sh -license /opt/bmc/BladeLogic/8.1/ApplicationRelease/phurnace.lic -mode 
#snapshot -profile '/home/deploy/ara/profiles/SCOM-JBoss.server' -output /tmp/live_config.xml

ara_path = "/opt/bmc/BladeLogic/8.1/ApplicationRelease"
prof_path = "#{ara_path}/server_profiles"
lic = "#{ara_path}/phurnace.lic"
phurn_path = "#{ara_path}/cli"
report_file = "snapshot_report_#{Time.now.to_i}.xml"   
cmd = "cd #{phurn_path}; ./runDeliver.sh -license #{lic} -mode snapshot -profile "
cmd += "#{prof_path}/#{params["server_profile"]} -output /tmp/#{report_file}"
write_to "CMD = " + cmd
# Run the command on the tagged host
result = run_command(params, cmd, '')

# Apply success or failure criteria
success = "doWork finished"
if result.index(success).nil?
  write_to "Command_Failed - term not found: [#{success}]\n"
else
  write_to "Success - found term: #{params["success"]}\n"
  write_to "=========== Phurnace Results ==========\n"
  write_to "Downloading Files..."
  write_to "  From: /tmp/#{report_file} To: #{params["SS_output_dir"]}"
  # download (also upload) is a capistrano function that uses the existing ssh channel for scp copy
  download("/tmp/#{report_file}", "#{params["SS_output_dir"]}/#{report_file}", :via => :scp)

  ipos = params["SS_output_dir"].index("automation_results")
  write_to "#{params["SS_base_url"]}/#{params["SS_output_dir"].slice((ipos + 7)..(ipos + 200))}/#{report_file}"
end
