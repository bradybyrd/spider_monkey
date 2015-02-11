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
# [integration_id=7]
SS_integration_dns = "http://ec2-184-73-150-83.compute-1.amazonaws.com:8080"
SS_integration_username = "sysadmin"
SS_integration_password = "-private-"
#=== End ===#

# Flag the script for direct execution
params["direct_execute"] = true

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
  unless result.index(params["success"]).nil?
    # Now check the xml for an error:
    ipos = result.index("<error>Please")
    req_status = "none"
    start_time = Time.now
    elapsed = 0
    until (elapsed > max_time || req_status == targ_status)
      cur_result = run_command(params, cmd, '', true)
      found = cur_result.scan(reg)
      unless found.empty?
        req_status = found[0].gsub("<status>","").gsub("<","")
      else
        elapsed = max_time + 1
      end
      write_to "Waiting(#{elapsed.floor.to_s}) - Current status: #{req_status}"
      sleep(30)
      elapsed = Time.now - start_time
    end
    if !ipos.nil? && ipos > 0
      write_to "Command_Failed: Error on BBDA Job: #{result.slice(ipos..(ipos+80))}"
    else
      write_to "Success - found term: #{params["success"]}\n"
    end
  else
    write_to "Command_Failed - term not found: [#{params["success"]}]\n"
  end
else
  write_to "Command_Failed - No Job ID specified\n"
end

