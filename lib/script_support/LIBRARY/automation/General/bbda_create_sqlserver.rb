################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# xml_job_file:
#   name: filename for xml job parameters
###

#=== SSH Integration Server: BBDA ===#
# [integration_id=3]
SS_integration_dns = "ec2-50-16-13-51.compute-1.amazonaws.com"
SS_integration_username = "deploy"
SS_integration_password = "-private-"
SS_integration_details = "perl_lib_path: /mnt/home/deploy/bbda_api"
#=== End ===#


reg = /perl_lib_path: .+?/
perl_lib_path = SS_integration_details.scan(reg)[0].gsub("perl_lib_path: ","").chomp
perl_lib_host = SS_integration_dns
hosts = [perl_lib_host]
params["user"] = SS_integration_username
#params["password"] = SS_integration_password

write_to "Executing on Hosts: #{hosts.inspect}"
role :all do # This tells Capistrano to perform the action on an array of hosts
 hosts
end

# Flag the script for direct execution
params["direct_execute"] = true

routine = "add_sqlserver_instance.pl"
args = params["xml_job_file"]
unless args.nil?
  # Run the command directly on the localhost
  cmd = "cd /mnt/home/deploy/bbda_api;perl #{routine} #{args}"
  result = run_command(params, cmd, '')
  params["success"] = "SUCCESS"
  # Apply success or failure criteria
  if result.index(params["success"]).nil?
    write_to "Command_Failed - term not found: [#{params["success"]}]\n"
  else# Result comes back: 
    #result=SUCCESS
    #id=15
    reg = /SUCCESS\nid=.+\n/m
    found = result.scan(reg)
    proc_id = found.empty? ? -1 : found[0].chomp.gsub("SUCCESS\nid=","").to_i
    pflag = set_property_flag("bbda_process_id", proc_id)
    write_to "Success - found term: #{params["success"]}\n"
  end
else
  write_to "Command_Failed: no configuration file specified"
end

