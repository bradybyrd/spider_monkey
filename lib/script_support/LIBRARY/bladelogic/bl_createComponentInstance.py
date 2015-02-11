#  BJB last update: 6/9/11
#  RJ update: 11/24/11 -> Fix syntax errors and input token keys
#  Denote arguments within a triple # comment block
###
# component_instance:
#   name: Name of component to create from template
###
# ========================================================================
# User Script
# ========================================================================

common_manager = common.CommonManager()

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
			
		if(props.has_key(type_flag)):
			if(props[type_flag].find("build") > -1):
				targets.append(serv)
	
	if(len(targets) > 0):	
		# Run the command on the server
		comp_template = params["SS_component_template_0"]
		comp_path = params["SS_component"] + "/" + comp_template
		writeTo("Creating new Bladelogic component")
		writeTo("  Based on: application: " + params["SS_application"])
		writeTo("  Using component template: " + comp_template)
		create_msg1 = "CREATING: component: " + params["component_instance"]
		writeTo("  " + create_msg1)
		create_msg2 = "from build on " + targets[0]
		writeTo("	 " + create_msg2)
		writeTo("  From Build server:" + ", ".join(targets))
		ss_object = streamstep.Streamstep(bl_profile_name,bl_role_name)
		ss_component = ss_object.createStreamstepComponent(params["SS_application"],params["SS_component"])
		#ss_component.addTemplateParameter(params["component_template"],"DEPLOY_REQUEST_" + timestamp(), create_msg1 + " " + create_msg2)
		ss_component.createComponent(params["component_instance"], comp_template,targets[0])

	else:
		writeTo("Command_Failed - no servers have a Bladelogic name and build type set")

else:
	writeTo("Command_Failed: No Servers selected for deploy")


