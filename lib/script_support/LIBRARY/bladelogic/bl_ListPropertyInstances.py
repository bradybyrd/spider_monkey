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
bl_property_class = blmanager.BLPropertyClass(bl_property_coord,bl_connect_manager,prop_dict_path)


prop_instances = bl_property_class.getInstanceNames()
writeTo("========== Listing Property Instances in Class: " + prop_dict_path)

for instance in prop_instances:
	writeTo(instance)
	inst = instance.split("/")[-1]
	pValues = bl_property_class.getInstancePropertyValues(inst)
	for curProp, propValue in pValues.items():
		writeTo("   " + curProp + " => " + propValue)
