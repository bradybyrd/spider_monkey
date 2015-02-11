# ----------- bl_sync_servers ---------------------#
###
# server_group:
#   name: Name of server to match
# target_environment:
#   description: Environment to match servers
###
# ----------- bl_sync_servers ---------------------#
# Instructions:
# This script queries servers from a bladelogic folder/group
# If the optional server group exists, it will use that, otherwise
# it will use all servers.

# -------------------- Override RBAC --------------------#
#bl_profile_name = "default"
#bl_role_name	= "DeployAdmins" 

# ----------- Initialization Routines -------------------#
bl_connect_manager = blmanager.BLConnectManager(bl_profile_name,bl_role_name) 
bl_component_coord = blmanager.BLComponentCoordinator(bl_connect_manager)
bl_server_coord = blmanager.BLServerCoordinator(bl_connect_manager)

# ----------- Set Variables for the Job Creation --------#
target_env = params["target_environment"]
group_name = params["server_group"]

# ----------- User Script -------------------#
if(len(target_env) > 1):

	if len(group_name) > 2:
		writeTo("#------- Listing Servers in: " + group_name + " --------------#")
		serverNames = bl_server_coord.getServersFromGroup(group_name)
	else:
		writeTo("#------- Listing All Servers --------------#")
		serverNames = bl_server_coord.getServerNames()

	outp = "\nname, environment\n"
	for name in serverNames:
		writeTo(name)
		outp += name + ", " + target_env + "\n"

	writeTo("#------- Synching Servers in " + target_env + " --------------")
	set_server_flag(outp)
else:
	writeTo("Server environment not specified")
