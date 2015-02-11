#!/usr/bin/jython
# coding=UTF-8
# ========================================================================
# SCRIPT NAME   : BLADELOGIC_SCRIPT_HEADER
# VERSION: 1.0 (05/10/2010)
#     - Header file to be mated with custom BL scripts
# ========================================================================

# ========================================================================
# IMPORT DECLARATIONS
# ========================================================================

import sys
import re
import os
import time
import codecs
import yaml

# BJB 7/8/10
# Set envrironment variables
# THe $$ variables will be replaced during execution
os.putenv('JYTHON_HOME' ,'/usr/local/jython')
#os.putenv('_SS_USERNAME' ,'$$BLADELOGIC_USERNAME')
#os.putenv('_SS_PASSWORD' ,'$$BLADELOGIC_PASSWORD')
os.putenv('_SS_ROLENAME' ,'$$BLADELOGIC_ROLENAME')
os.putenv('_SS_PROFILE' ,'$$BLADELOGIC_PROFILE')
os.putenv('_SS_INPUTFILE' ,'$$BLADELOGIC_INPUTFILE')
os.putenv('_SS_APPPATH' ,'$$APPPATH')

# ========================================================================
# BLADELOGIC
# ========================================================================

import bladelogic.cli.CLI as blcli
#from com.bladelogic.client import BRProfile
INSTALLATION_PATH=os.environ["_SS_APPPATH"]
LIBRARY_PATH=unicode(INSTALLATION_PATH + '/PYLIB',"utf-8")
sys.path.append(LIBRARY_PATH)
import common
import blmanager
import streamstep

global FHandle
global Params

def load_input_params(file_name):
	# BJB - 7/8/10 Quick YAML reader (1-dimensionaal)
	fil = codecs.open(unicode(file_name,"utf-8"), "r","utf-8")
	dataMap = yaml.load(fil.read())
	result_list = streamstep.strip_private_flags(dataMap)
	Params = result_list
	return result_list

def writeTo(message):
	FHandle.writelines(message + "\n")
	print message.encode("utf-8")
	
def write_to(message):
	writeTo(message)

def getParam(key_name):
	if Params.has_key(key_name):
		res = Params[key_name]
	else:
		res = ""
	return res

def set_property_flag(prop, value = "nil"):
	acceptable_fields = ["name", "value", "environment", "global", "private"]
	flag = "#------ Block to Set Property ---------------#\n"
	if(value == "nil"):
		flag += set_build_flag_data("properties", prop, acceptable_fields)
	else:
		flag += "$$SS_Set_property{" + str(prop) + "=>" + str(value) + "}$$"
	flag += "\n#------- End Set Property ---------------#\n"
	writeTo(flag)
	return flag

def set_server_flag(servers):
	# servers = "server_name, env\ncserver2_name, env2"
	acceptable_fields = acceptable_fields = ["name", "environment", "group"]
	flag = "#------ Block to Set Servers ---------------#\n"
	flag += set_build_flag_data("servers", servers, acceptable_fields)
	flag += "\n#------ End Set Servers ---------------#\n"
	writeTo(flag)
	return flag

def set_component_flag(components):
	# comps = "comp_name, version\ncomp2_name, version2"
	flag = "#------ Block to Set Components ---------------#\n"
	acceptable_fields = ["name", "version"]
	flag += set_build_flag_data("components", components, acceptable_fields)
	flag += "\n#------ End Set Components ---------------#\n"
	writeTo(flag)
	return flag

def set_titles_acceptable(cur_titles, acceptable_titles):
	acceptable = "\n".join(acceptable_titles)
	found_all = 1
	for cur in cur_titles:
		if cur.strip() in acceptable:
			found1 = 1
		else:
			found_all = 0
	return found_all

def set_build_flag_data(set_item, set_data, acceptable_titles):
	msg = ""
	flag = ""
	lines = set_data.split("\n")
	titles = []
	l = lines[0].split(",")
	for k in l:
		titles.append(k.strip())

	if set_titles_acceptable(titles, acceptable_titles):
		flag += "$$SS_Set_" + set_item + "{\n"
		flag += ", ".join(titles) + "\n"
		for line in lines[1:]:
			if(len(line.split(",")) == len(titles)):
				flag += line + "\n"
		else:
			if len(line) > 1:
				msg += "Skipped: " + line

		flag += "}$$\n"
	else:
		flag += "ERROR - Unable to set " + set_item + " - improper format\n"
	flag += msg
	return flag

def set_application_version(prop, value):
	# set_application_flag(app_name, version)
	flag = "#------ Block to Set Application Version ---------------#\n"
	flag += "$$SS_Set_application{" + prop + "=>" + value + "}$$"
	flag += "\n#------ End Set Application ---------------#\n"
	writeTo(flag)
	return flag


def read_hash(hsh):
	#parse a hash, return a dict
	#{'IP Address'=>'2.3.4.5','target'=>'bullseye; buttons'}
	if hsh[0] == "{":
		tmp = hsh.replace("{", "").replace("}", "")
		tmp = tmp.replace(";", "SS__059").replace("','",";").replace("'","")
		res = dict(item.split("=>"))
		for k, v in res.items():
			res[k] = v.replace("SS__059", ";")
	else:
		res = {"no_data":"none"}
	
	return res	
	
def get_server_list(params):
	rxp = 'server\d+_'
	slist = {}
	lastcur = -1.0
	curname = ""
	sorted = params.keys()
	sorted.sort()
	for key in sorted:
		found = re.search(rxp,key)
		if(found is None):
			# skip it
			done = 1
		else:
			server = found.group(0)
			cur = round(int(server.replace("_","").replace("server","")),-3)
			#print str(cur) + ") " + key
			if cur == lastcur:
				prop = key.replace(server, "")
				if(params[key] is None):
					slist[curname][prop] = ""
				else:
					slist[curname][prop] = params[key]
			else: # new server
				lastcur = cur
				curname = params[key]
				slist[curname] = {}

	return slist

def timestamp():
	path = os.environ["_SS_INPUTFILE"]
	pos = unicode(path,"utf-8").find(unicode('blinput_',"utf-8"))
	return(path[(pos + 8):(pos + 8 + 10)])

def output_separator(phrase):
  divider = "==========================================================="
  lenadj = len(divider) - len(phrase)
  "\n" + divider[0:20] + " " + phrase + " " + divider[0:lenadj] + "\n"


########## END of Header Script #############

bl_profile_name = os.environ["_SS_PROFILE"]
bl_role_name	= os.environ["_SS_ROLENAME"] 

# Load the input parameters file and parse as yaml
params = load_input_params(os.environ["_SS_INPUTFILE"]) 
# Input params need to include
#   Application
# Open the output file and note it in the return message: sets FHandle
FHandle = codecs.open(params["SS_output_file"], "a","utf-8")
