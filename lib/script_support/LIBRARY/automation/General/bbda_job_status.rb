################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# job_id:
#   name: Name of command
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

routine = "checkprocess.pl"
#If a previous step set the property for job_id, use it
job_id = params["bbda_job_id"].to_i > 0 ? params["bbda_job_id"] : params["job_id"]
args = job_id

if job_id.to_i > 0
  # Run the command directly on the localhost
  cmd = "cd /mnt/home/deploy/bbda_api;perl #{routine} #{args}"
  result = run_command(params, cmd, '')

  params["success"] = "SUCCESS"
  # Apply success or failure criteria
  if result.index(params["success"]).nil?
    write_to "Command_Failed - term not found: [#{params["success"]}]\n"
  else
    # Now check the xml for an error:
    ipos = result.index("<error>Please")
    if !ipos.nil?
      write_to "Command_Failed: Error on BBDA Job: #{result.slice(ipos..(ipos+80))}"
    else
      write_to "Success - found term: #{params["success"]}\n"
    end
  end
else
  write_to "Command_Failed - No Job ID specified\n"
end

