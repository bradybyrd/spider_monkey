# -------------------- bl_runCLI_command --------------------#
###
# cli_class:
#   description: name of cli class
# cli_command:
#   description: name of command
# cli_params:
#   description: comma separated list of items (no spaces)
###
# -------------------- bl_runCLI_command --------------------#
# runs an arbitrary CLI command

# -------------------- Override RBAC --------------------#
#bl_profile_name = "default"
#bl_role_name	= "DeployAdmins" 

# ----------- Initialization Routines -------------------#
bl_connect_manager = blmanager.BLConnectManager(bl_profile_name,bl_role_name) 
bl_component_coord = blmanager.BLComponentCoordinator(bl_connect_manager)

# ----------- Set Local Variables for Routine --------#
cli_params = params["cli_params"].split(",")
cli_class = params["cli_class"]
cli_cmd = params["cli_command"]

# ----------- User Script -------------------#
result = bl_connect_manager.run(cli_class,cli_cmd,cli_params)

writeTo("#------------ Running Bladelogic CLI Command --------------")
writeTo("#-- Command: " + cli_class + ", " + cli_cmd + ", [" + cli_params + "]")
writeTo("#-- Result: --")
writeTo(result)

