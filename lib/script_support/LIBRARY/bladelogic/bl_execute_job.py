#--- bl_Execute_Job ---#
# Denote arguments within a triple # comment block
###
# job_name:
#   name: name of job to execute
###

# ========================================================================
# MAIN SCRIPT 
# ========================================================================

#-- Note: requires the property cur_deploy_job_name to be set
#-- Component Template in application model must match the name in bladelogic

def striplist(l):
	return([x.strip() for x in l])

bl_profile_name = os.environ["_SS_PROFILE"]
bl_role_name	= os.environ["_SS_ROLENAME"] 

#  Initialize the library modules
common_manager = common.CommonManager()
bl_connect_manager = blmanager.BLConnectManager(bl_profile_name,bl_role_name) 
bl_job_coord = blmanager.BLJobCoordinator(bl_connect_manager)

# ========================================================================
# User Script
# ========================================================================

app_name = params["SS_application"]
if (len(params["job_name"].strip()) > 0):
	job_names = params["job_name"].split(",")
	job_names = striplist(job_names)
	comp_template = params["SS_component_template_0"] # Note always uses first component_template in the list!
	comp_path = params["SS_component"] + "/" + comp_template
	writeTo("Executing Bladelogic Deploy Job")
	writeTo("  Based on: application: " + params["SS_application"])
	writeTo("  Using component: " + params["SS_component"])
	writeTo("  EXECUTING: jobs: " + ", ".join(job_names))
	# Start with a valid base object
	ss_object = streamstep.Streamstep(bl_profile_name,bl_role_name)
	#  The component object preserves the group folder paths
	ss_component = ss_object.createStreamstepComponent(app_name,params["SS_component"])
	# Execute the Job based on the Package 
	for job in job_names:
		writeTo("  Executing Job (synch): " + str(job))
		#  Queue for immediate synchronous execution
		ss_component.executeComponentJob(job, comp_template)

else:
	writeTo("Command_Failed: No job specified")



