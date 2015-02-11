#--- bl_Create_Deploy_Job ---#
# Denote arguments within a triple # comment block
###
# package:
#   name: Name of package to deploy
# component_template:
#   name: component template to use
###

# ========================================================================
# MAIN SCRIPT 
# ========================================================================

bl_profile_name = os.environ["_SS_PROFILE"]
bl_role_name	= os.environ["_SS_ROLENAME"] 

#  Initialize the library modules
common_manager = common.CommonManager()
bl_connect_manager = blmanager.BLConnectManager(bl_profile_name,bl_role_name) 
bl_job_coord = blmanager.BLJobCoordinator(bl_connect_manager)

# ========================================================================
# User Script
# ========================================================================
  # The list of servers is in the input file
servers = get_server_list(params)
targets = []
if(len(servers) > 0):
	# Loop through the server list and get the Bladelogic server name property
	bl_flag = "Bladelogic_server_name"
	type_flag = "ServerPurpose"
	for serv, props in servers.items():
		writeTo(serv + "- Properties: ")
		for k,v in props.items():
			writeTo(k + " => " + v)
			
		if(props.has_key(bl_flag) & props.has_key(type_flag)):
			if((props[type_flag] == "appserver") & (len(props[bl_flag]) > 4) ):
				targets.append(props[bl_flag])
	
	if(len(targets) > 0):	
		comp_path = params["SS_component"] + "/" + params["component_template"]
		job_name = params["package"] + ":" + targets[0] + timestamp()
		writeTo("Creating new Bladelogic Deploy Job")
		writeTo("  Based on: application: " + params["SS_application"])
		writeTo("  Using component: " + params["SS_component"])
		writeTo("  CREATING: job: " + job_name)
		writeTo("   deploy on server " + ", ".join(targets))
		# Start with a valid base object
		ss_object = streamstep.Streamstep(bl_profile_name,bl_role_name)
		#  The component object preserves the group folder paths
		ss_component = ss_object.createStreamstepComponent(params["SS_application"],params["SS_component"])
		# Create the Job based on the Package 
		ss_job = ss_component.createJobFromPackage(job_name, params["package"],targets[0], params["component_template"])
		targets.remove(targets[0])  #get rid of first server already set in job creation
		# Add Additional Server targets
		if (len(targets) > 0):
			result = bl_job_coord.addServersToJob(ss_job, ", ".join(targets))
		writeTo("  Executing Job (synch): " + str(ss_job))
		#  Queue for immediate synchronous execution
		ss_component.executeJob(ss_job)	
	else:
		writeTo("Command_Failed: No AppServers selected for deploy")
else:
	writeTo("Command_Failed: No Servers selected for deploy")

