#------------ Set Items Example ------------#
# Demonstrates how to set various items, properties
#  servers and components from automation
###
# property_name:
#   description: Name of property to set
# property_value:
#   description: value for prop
# comp_version:
#   description: value for version
###

if len(params["property_name"]) < 1:
	property_name = "a_test_property"
else:
	property_name = params["property_name"]
if len(params["property_value"]) < 1:
	property_value = "default Value"
else:
	property_value = params["property_value"]
if len(params["comp_version"]) < 1:
	comp_version = "a_Version-1"
else:
	comp_version = params["comp_version"]

if params.has_key("SS_environment") and len(params["SS_environment"]) > 1:
	env = params["SS_environment"]
	comp = params["SS_component"]
	result = "\n".join(os.listdir(os.getcwd()))
  
  # Create or set the property value
	set_property_flag(property_name, property_value)

  # Alternate - bulk set syntax
	properties = "name, value, component, environment\n"
	properties += property_name + ", " + property_value + ", SS_RailsApp, production\n" 
	properties += "app_user, brady, SS_RailsApp, production\n"
	set_property_flag(properties)
  
  
  # Create or update the servers
  #  create a list of servers and environments
  #  separated by commas and broken with cr
	servers = "name, environment\n"
	servers += "bl_server1, " + env + "\n"
	servers += "bl_server1, " + env + "\n"
	servers += "a_server1, " + env + "\n"
	set_server_flag(servers)

  # Create or update components
  #  create a list of components and versions
  #  separated by commas and broken with cr
	components = "name, version\n"
	components += comp + ", " + comp_version + "\n"
	components += "a_new_comp, " + comp_version + "\n"
	set_component_flag(components)
  
	writeTo(result)
else:
	writeTo("Command_Failed: no app/comp/environment set")
	
	