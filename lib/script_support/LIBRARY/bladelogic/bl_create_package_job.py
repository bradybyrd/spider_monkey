#--- bl_Create_Package_Job ---#
# Denote arguments within a triple # comment block
###
# package:
#   name: Name of package to deploy
# package_path:
#   name: folder path to package
# server_target:
#   name: optional - if executing from test
###
# ----------- bl_create_package_job ---------------------#
# Instructions:
# This script creates a job from an existing package
# Then assigns server targets to the job based on the checked
#  servers in the step.  If there are no checked servers, it
#  will use the server_target argument.
# Then the script executes the job synchronously
# The script also sets the 'last_bljob_run' property
#  to point to the id of the job results

# -------------------- Override RBAC --------------------#
#bl_profile_name = "default"
#bl_role_name	= "DeployAdmins" 

# ----------- Initialization Routines -------------------#
common_manager = common.CommonManager()
bl_connect_manager = blmanager.BLConnectManager(bl_profile_name,bl_role_name) 
bl_job_coord = blmanager.BLJobCoordinator(bl_connect_manager)

# ----------- Set Variables for the Job Creation --------#
execute_job = False # Set to true for immediate execution
package_group = params["package_path"]
package_name = params["package"]
job_name = package_name + "_" + timestamp()
job_group = package_group
server = params["server_target"]


# ----------- Get Selected Servers  ----------------------#
# The list of servers is in the input file
servers = get_server_list(params)
targets = []
if(len(servers) > 0):
	for serv, props in servers.items():
		writeTo("#-----" + serv + "- Properties -------------# ")
		for k,v in props.items():
			writeTo(k + " => " + v)
		targets.append(serv)	

elif(len(server) > 1):
	targets.append(server)
else:
	writeTo("Command_Failed: No Servers selected for deploy")

if(len(targets) > 0):	
	writeTo("#------ Creating new Bladelogic Deploy Job --------#")
	#writeTo("  Based on: application: " + params["application"])
	#writeTo("  Using component: " + params["component"])
	writeTo("  CREATING: job: " + job_name)
	writeTo("   deploy on server " + ", ".join(targets))
	# Create the Job based on the Package 
	ss_job = bl_job_coord.createDeployJob(package_group, package_name, job_group, job_name, targets[0])
	set_property_flag("last_bljob", ss_job)
	# Add Additional Server targets
	if(len(targets) > 1):
		result = bl_job_coord.addServersToJob(ss_job, ", ".join(targets[1:100]))
	if(execute_job):
		writeTo("  Executing Job (synch): " + str(ss_job))
		#  Queue for immediate synchronous execution
		job_run_id = bl_job_coord.executeJobAndWait(ss_job)
		set_property_flag("last_bljob_run", job_run_id)
else:
	writeTo("Command_Failed: No AppServers selected for deploy")
