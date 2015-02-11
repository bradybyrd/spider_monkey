#--- bl_list_depot_packages ---#
# Denote arguments within a triple # comment block
###
# depot_path:
#   name: folder/group path in depot
# target:
#   name: optional - if target exists in path
###
# ----------- bl_list_depot_packages ---------------------#
# Instructions:
# This script lists the packages in a depot folder/group
# If the optional target is included then the script checks
# for the existence of target in the list of packages
# returning an error if the target does not exist

# -------------------- Override RBAC --------------------#
#bl_profile_name = "default"
#bl_role_name	= "DeployAdmins" 

# ----------- Initialization Routines -------------------#
common_manager = common.CommonManager()
bl_connect_manager = blmanager.BLConnectManager(bl_profile_name,bl_role_name) 
bl_depot_coord = blmanager.BLDepotCoordinator(bl_connect_manager)

# ----------- Set Variables for the Job Creation --------#
package_group = params["depot_path"]
package_name = params["target"]


# ----------- Get the package list  ----------------------#
if(len(package_group) > 0):	
	writeTo("#---------- Listing Bladelogic Deploy Packages ------------#")
	writeTo("#----------   In Group: " + package_group)
	ss_packages = bl_depot_coord.listPackagesInGroup(package_group)
	found_packages = ", ".join(ss_packages)
	if len(package_name) > 2:
		if package_name in found_packages:
			writeTo("Found package: " + package_name)
		else:
			writeTo("Command_Failed: no package by the name: " + package_name)
	set_property_flag("returned_packages", found_packages)
	writeTo("Packages:\n" + "\n".join(ss_packages) + "\n")
else:
	writeTo("Command_Failed: No Group entered")
