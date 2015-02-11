###
# server_search:
#   name: Name of server to match
# group_name:
#   name: optional - to list servers in a (smart)group
###
# Denote arguments within a triple # comment block

# -------------------- Override RBAC --------------------#
#bl_profile_name = "default"
#bl_role_name	= "DeployAdmins" 

# ----------- Initialization Routines -------------------#
bl_connect_manager = blmanager.BLConnectManager(bl_profile_name,bl_role_name) 
bl_server_coord = blmanager.BLServerCoordinator(bl_connect_manager)

# ----------- Set Local Variables for Routine --------#
group_name = params["group_name"]
target_server = params["server_search"]

# ----------- User Script -------------------#
if len(group_name) > 2:
	writeTo("#-------Listing Servers in: " + group_name + "--------------#")
	serverNames = bl_server_coord.getServersFromGroup(group_name)
else:
	writeTo("#-------Listing All Servers --------------#")
	serverNames = bl_server_coord.getServerNames()
success = 0

for name in serverNames:
  writeTo(name)
  if name == target_server:
    success = 1

if(success or len(target_server) < 1):
   msg = "Success: Server " + target_server + " found"
else:
   msg = "Command_Failed: Server " + target_server + " not found"
    
writeTo(msg) 
