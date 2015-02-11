#--- bl_list_jobs ---#
# Denote arguments within a triple # comment block
###
# job_path:
#   name: folder/group path in depot
# target:
#   name: optional - if target exists in path
###
# ----------- bl_list_depot_jobs ---------------------#
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
job_name = params["target"]


# ----------- Get the job list  ----------------------#
if(len(job_group) > 0):	
	writeTo("#---------- Listing Bladelogic Jobs ------------#")
	writeTo("#----------   In Group: " + job_group)
	ss_jobs = bl_job_coord.listJobsInGroup(job_group)
	found_jobs = ", ".join(ss_jobs)
	if len(job_name) > 2:
		if job_name in found_jobs:
			writeTo("Found job: " + job_name)
		else:
			writeTo("Command_Failed: no job by the name: " + job_name)
	set_property_flag("returned_jobs", found_jobs)
	writeTo("Jobs:\n" + "\n".join(ss_jobs) + "\n")
else:
	writeTo("Command_Failed: No Group entered")
