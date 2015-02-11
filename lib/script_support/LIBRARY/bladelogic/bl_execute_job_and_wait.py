#--- bl_execute_job_and_wait ---#
# Denote arguments within a triple # comment block
###
# job_path:
#   name: folder/group path in depot
# target_job:
#   name: name of job
# job_type:
#   name: type of job (DeployJob,NSHScriptJob,BatchJob)
###
# ----------- bl_execute_job_and_wait ---------------------#
# Instructions:
# This script lists the jobs in a folder/group
# If the optional target is included then the script checks
# for the existence of target in the list of jobs
# returning an error if the target does not exist

# -------------------- Override RBAC --------------------#
#bl_profile_name = "default"
#bl_role_name	= "DeployAdmins" 

# ----------- Initialization Routines -------------------#
common_manager = common.CommonManager()
bl_connect_manager = blmanager.BLConnectManager(bl_profile_name,bl_role_name) 
bl_job_coord = blmanager.BLJobCoordinator(bl_connect_manager)

# ----------- Set Variables for the Job Creation --------#
job_group = params["job_path"]
job_name = params["target_job"]
job_type = params["job_type"]


# ----------- Execute the Job  ----------------------#
if(len(job_group) > 0):	
	writeTo("#---------- Executing Bladelogic Jobs ------------#")
	writeTo("#----------   In Group: " + job_group)
	ss_job = bl_job_coord.getJobKey(job_group, job_name, job_type)
	if len(str(ss_job)) > 3:
		result = bl_connect_manager.run("Job","executeJobAndWaitForRunID",ss_job)
		set_property_flag("returned_jobs", job_name)
	else:
		writeTo("Command_Failed: Couldn't find job: " + job_name + " in " + job_group)
else:
	writeTo("Command_Failed: No Group entered")
