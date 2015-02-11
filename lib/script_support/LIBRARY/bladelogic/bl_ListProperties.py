#  Denote arguments within a triple # comment block
###
# base_property_class:
#   name: Name of property class like prop/prop
###
# ========================================================================
# User Script
# ========================================================================

prop_dict_path = params["base_property_class"]

if (len(prop_dict_path) < 1):
   sys.exit(-1)

# ========================================================================
# MAIN SCRIPT
# ========================================================================

bl_connect_manager = blmanager.BLConnectManager(bl_profile_name,bl_role_name)
bl_property_coord  = blmanager.BLPropertyCoordinator(bl_connect_manager)


prop_dict_entries = bl_property_coord.getClassNamesFromRoot(prop_dict_path)
writeTo("========== Listing Property Classes in Class: " + prop_dict_path)
writeTo("#--- Properties:")
bl_property_class = blmanager.BLPropertyClass(bl_property_coord,bl_connect_manager,prop_dict_path)
props = bl_property_class.getPropertyNames()
for prop in props:
	writeTo("\t" + prop)
	
for entry in prop_dict_entries:
	writeTo("Class: " + entry)
	writeTo("#--- Listing Properties in Class: " + entry)
	bl_property_class = blmanager.BLPropertyClass(bl_property_coord,bl_connect_manager,prop_dict_path + entry.replace(prop_dict_path,""))
	props = bl_property_class.getPropertyNames()
	for prop in props:
		writeTo("\t" + prop)
	
