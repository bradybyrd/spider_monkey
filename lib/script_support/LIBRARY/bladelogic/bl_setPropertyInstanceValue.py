#  Denote arguments within a triple # comment block
###
# base_property_class:
#   description: Name of property class like prop/prop
# instance_name:
#   description: name of instance
# property_name:
#   description: name of property
# property_value:
#   description: value to set
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
propName = params["property_name"]
instanceName = params["instance_name"]
propValue = params["property_value"]
instanceFound = False
propertyFound = False

if((len(propName) < 1) or (len(instanceName) < 1) or (len(propValue) < 1)):
  writeTo("Argument values absent")
  sys.exit(-1)

bl_connect_manager = blmanager.BLConnectManager(bl_profile_name,bl_role_name)
bl_property_coord  = blmanager.BLPropertyCoordinator(bl_connect_manager)
bl_property_class = blmanager.BLPropertyClass(bl_property_coord,bl_connect_manager,prop_dict_path)

writeTo("Setting the " + instanceName + " instance of " + propName + " property in class: " + prop_dict_path + " to: " + propValue)
propClass = bl_property_coord.getBLPropertyClass(prop_dict_path)
propClassInstances = propClass.getInstanceNames()
# List all instances then classes
for instPath in propClassInstances:
  inst = instPath.split("/")[-1]
  if(inst == instanceName):
    instanceFound = True

pValues = propClass.getInstancePropertyValues(inst)
for curProp, propVal in pValues.items():
  #writeTo("   " + curProp + " => " + propVal)
  if(curProp == propName):
    propertyFound = True

if(instanceFound and propertyFound):
  writeTo("Changing: " + propName + " to: " + propValue + " in " + instanceName)
  propClass.updateInstancePropertyValue(instanceName,propName,propValue)
else:
  writeTo("Command_Failed: " + propName + " or " + instanceName + " not found.")


