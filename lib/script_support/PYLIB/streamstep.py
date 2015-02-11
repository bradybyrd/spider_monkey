#!/usr/bin/jython
# coding=UTF-8
# ========================================================================
# LIBRARY NAME  : STREAMSTEP.PY
# PURPOSE       :
#     - Build the logic for specific BRPM operations here
#
# VERSION: 1.0 (05/10/2010)
#     - initial classes to interact with Bladelogic
# ========================================================================

# ========================================================================
# IMPORT DECLARATIONS
# ========================================================================

import sys
import re
import os
import time
import base64

from java.lang import Class

# ========================================================================
# BLADELOGIC
# ========================================================================

import bladelogic.cli.CLI as blcli

# ========================================================================
# BRPM
#    ACTION: update based on installation path
# ========================================================================

INSTALLATION_PATH=os.environ["_SS_APPPATH"]
LIBRARY_PATH=INSTALLATION_PATH + '/PYLIB'
PRIVATE_PREFIX = "__SS__" # Must also change in config/environment.rb and script_helper.rb

sys.path.append(LIBRARY_PATH)

import blmanager as blm
import common

"""
=======================================================================
NAME: BRPM
PURPOSE:
    - Consolidates the logic of BRPM activities here.
=======================================================================
"""

class Streamstep:
	"Streamstep consolidated functions"
	
	def __init__(self,bl_profile_name,bl_role_name):
		self.bl_connect_mgr	= blm.BLConnectManager(bl_profile_name,bl_role_name)
		self.common = self.bl_connect_mgr.getCommon()
		self.base_group_folder = '/BRPM/Applications'
	
	def createStreamstepComponent(self,application_name,component_name):
		ss_component_object = StreamstepComponent(self.bl_connect_mgr,application_name,component_name)
		return ss_component_object

	def createStreamstepPackage(self,package_name):
		ss_package_object = StreamstepPackage(self.bl_connect_mgr, package_name)
		return ss_package_object

	def createStreamstepJob(self,job_name):
		ss_job_object = StreamstepJob(self.bl_connect_mgr, job_name)
		return ss_job_object

	def createStreamstepPropertyClass(self,property_class):
		ss_property_object = StreamstepPropertyClass(self.bl_connect_mgr, property_class)
		return ss_property_object

	def createStreamstepPlanManager(self,package_name,lc,lc_policies,lc_property):
		ss_lc_manager = StreamstepPlanManager(self.bl_connect_mgr,
							   package_name,
							   lc,
							   lc_policies,
							   lc_property)
		return ss_lc_manager
		

			
class StreamstepComponent:
	"Streamstep Component Manager"
	
	def __init__(self,bl_connect_mgr,application_name,component_name):
		self.bl_connect_mgr = bl_connect_mgr
		self.common = self.bl_connect_mgr.getCommon()
		self.bl_component_coord = blm.BLComponentCoordinator(self.bl_connect_mgr)
		self.base_group_folder = '/BRPM'		
		self.ss_application = application_name
		self.ss_component = component_name
		self.group_application_path = self.base_group_folder + '/' + application_name
		self.group_component_base_path = self.group_application_path # + '/Components'
		self.group_component_path = self.group_application_path + '/' + component_name

	def renameApplication(self,new_application_name):
		if self.bl_component_coord.existsTemplateGroup(self.group_application_path) == 1:
			self.bl_component_coord.renameTemplateGroup(self.base_group_folder,
								    self.ss_application,
								    application_name)
		
	def renameSSComponent(self,new_component_name):
		if self.bl_component_coord.existsTemplateGroup(self.group_component_path) == 1:
			self.bl_component_coord.renameTemplateGroup(self.group_component_base_path,
								    self.ss_component,
								    new_component_name)
		
	def renameTemplate(self,param_old_template,param_new_template):
		self.common.printInfo('TODO: rename Component Template')
	
	def createTemplate(self,template_name):
		self.bl_component_coord.createTemplateGroup(self.group_component_path)
		self.bl_component_coord.createTemplate(self.group_component_path,template_name)
	
	def addTemplateParameter(self,template_name,local_var,default_value):
		#
		# 1. assumes all the parameters are string ...
		#
		self.bl_component_coord.addParameterToTemplate(self.group_component_path,
							       template_name,
							       local_var,
							       local_var,
							       '',
							       'true',
							       'false',
							       default_value)
		
	def createComponent(self,comp_name, template_name, target):
		#self.bl_component_coord.createComponentGroup(self.group_component_path)
		self.bl_component_coord.createComponent(comp_name,
							self.group_component_path,
							template_name,
							target)
	
	def addTemplateToPackage(self,package_name,template_name,options={}):
		print "Adding template to package: " + self.group_component_path + "/" + template_name
		component_key= self.findDefaultComponentKey(template_name)
		depotCoordinator = blm.BLDepotCoordinator(self.bl_connect_mgr)
		depotCoordinator.createGroup(self.group_component_path + "/" + template_name)
		self.bl_component_coord.appendPackage(self.group_component_path + "/" + template_name,
						      package_name,
						      component_key,
						      options)

	def createJobFromPackage(self, job_name, package_name, param_target, component_template = "none", force_path = "no"):
		jobCoordinator = blm.BLJobCoordinator(self.bl_connect_mgr)
		grp_path = self.group_component_path
		if(component_template != "none"):
		  grp_path = grp_path + "/" + component_template
		print "GroupPath: " + grp_path
		if force_path == "no":
			pkg_path = grp_path
		else:
			pkg_path = force_path
		jobCoordinator.createJobGroup(grp_path)
		curTime = time.localtime(time.time())
		ts = "_" + str(curTime[0])+str(curTime[1])+str(curTime[2])+str(curTime[3])+str(curTime[4])
		#job_name = package_name + ':' + param_target + ts
		deploy_job_key = jobCoordinator.createDeployJob(pkg_path,
								package_name,
								grp_path,
								job_name,
								param_target)
		return(deploy_job_key)

	def executeJob(self, job_key):
		jobCoordinator = blm.BLJobCoordinator(self.bl_connect_mgr)
		return jobCoordinator.executeJobAndWait(job_key)


	def executeComponentJob(self, job_name, component_template):
		grp_path = self.group_component_path
		grp_path = grp_path + "/" + component_template
		jobCoordinator = blm.BLJobCoordinator(self.bl_connect_mgr)
		job_key = blm.BLJobCoordinator.getJobKey(jobCoordinator, grp_path, job_name)
		return jobCoordinator.executeJobAndWait(job_key)
						
	def findDefaultComponentKey(self,template_name):
		#
		# 1. if there is only one component, use it as a default
		# 2. if not, then select based on name or first one
		#
		comp_path = self.group_component_path # + "/" + self.ss_component
		print "Looking for : " + comp_path + "/" + template_name
		component_key_list = self.bl_component_coord.getComponentKeysInTemplate(comp_path,template_name)
		for component_key in component_key_list:
			return component_key
			
		self.common.printError('Template: ' + template_name + ' has no component instances.')
		sys.exit(-1)

class StreamstepPackage:
	"Streamstep Package Object"

	def __init__(self,bl_connect_mgr,package_name):
		self.bl_connect_mgr = bl_connect_mgr
		self.common = self.bl_connect_mgr.getCommon()
		self.bl_depot_coord = blm.BLDepotCoordinator(self.bl_connect_mgr)
		self.bl_package_coord = blm.BLPackageCoordinator(self.bl_connect_mgr,self.bl_depot_coord)
		self.package_name = package_name
	#
	# NEW FUNCTIONS TO SUPPORT MANAGING LOCAL PARAMETERS
	#
	
	#
	# Use this function to add parameters to a class: string,boolean,integer,'class-name'
	#
	def addSimpleParameter(self,parameter_name,property_type):
		self.bl_package_coord.addSimpleParameter(self.package_name,parameter_name,property_type)

	#
	# Use this function to update the default value of the parameter
	#
	def setLocalDefaultParameter(self,parameter_name,property_value):
		self.bl_package_coord.setBLPackageParameter(self.package_name,parameter_name,property_value)

class StreamstepJob:
	"Streamstep Job Object"

	def __init__(self,bl_connect_mgr,job_name):
		self.bl_connect_mgr = bl_connect_mgr
		self.common = self.bl_connect_mgr.getCommon()
		self.bl_depot_coord = blm.BLDepotCoordinator(self.bl_connect_mgr)
		self.bl_package_coord = blm.BLPackageCoordinator(self.bl_connect_mgr,self.bl_depot_coord)
		self.bl_job_coord = blm.BLJobCoordinator(self.bl_connect_mgr)
		self.job_name = job_name
	#
	# Use this function to update the default value of the parameter
	#
	def setLocalParameter(self,parameter_name,property_value):
		self.bl_job_coord.setBLJobParameter(self.job_name,parameter_name,property_value)

class StreamstepPropertyClass:
	"Streamstep Property Class"

	def __init__(self,bl_connect_mgr,property_class_name):
		self.bl_connect_mgr = bl_connect_mgr
		self.common = self.bl_connect_mgr.getCommon()
		self.bl_property_coord = blm.BLPropertyCoordinator(self.bl_connect_mgr)
		self.property_class_name = property_class_name
		self.bl_property_class = blm.BLPropertyClass(self.bl_property_coord,self.bl_connect_mgr,property_class_name)
	#
	# NEW FUNCTIONS TO SUPPORT MANAGING PARAMETERS THAT ARE ALSO PROPERTY CLASSES
	#
	def getInstances(self):
		return self.bl_property_class.getInstanceNames()
	
	def getInstancePropertyValues(self,var_instance_name):
		return self.bl_property_class.getInstancePropertyValues(var_instance_name)

	def instanceExists(self,var_instance_name):
		prop_instances = self.bl_property_class.getInstanceNames()
		for instance in prop_instances:
			if instance == prop_instance_name:
				return 'true'
		return 'false'

	def getInstanceAttribute(self,var_instance_name,var_attr):
		return self.bl_property_class.getInstancePropertyValue(var_instance_name,var_attr)

	def setInstanceAttribute(self,var_instance_name,var_attr,var_value):
		return self.bl_property_class.setInstancePropertyValue(var_instance_name,var_attr,var_value)


#
# Streamstep
#
class StreamstepPlanManager:
	"Streamstep Manager of Plans"
  
	def __init__(self,bl_connect_mgr,package_name,plans,plan_templates,plan_property):
		self.bl_connect_mgr = bl_connect_mgr
		self.common = self.bl_connect_mgr.getCommon()
		self.bl_depot_coord = blm.BLDepotCoordinator(self.bl_connect_mgr)
		self.bl_package_coord = blm.BLPackageCoordinator(self.bl_connect_mgr,self.bl_depot_coord)
		self.bl_package_name = package_name
		self.plans = plans
		self.lc_length = len(self.plans)
		self.plan_templates = plan_templates
		self.plan_property = plan_property

	def initialize(self):
		#
		# NOTE: DOES NOTHING, MANUALLY CREATED THE PROPERTY 'STREAMSTEP_PHASE'
		#       IN THE PROPERTY DICTIONARY
		#
		print "REMEMBER: CREATE THE " + self.plan_property + " AS A STRING ON THE BLPACKAGE"

	def demote(self):
		#
		# demote the package down the plan
		#
		print "Demoting Object (if possible)"
		current_phase = self.getPhase()
		count = 0
		demote_index = 0
		while count < self.lc_length:
		    if self.plans[count] == current_phase:
			    if count == 0:
				    demote_index = 0
			    else:
				    demote_index = count - 1
		    count = count + 1
		phase_name = self.plans[demote_index]
		self.change(phase_name)
	
	def promote(self):
		#
		# promote a package up the plan
		#
		print "Promoting Object (if possible)"
		current_phase = self.getPhase()
		count = 0
		promote_index = 0
		while count < self.lc_length:
		    if self.plans[count] == current_phase:
			    if count == self.lc_length:
				    promote_index = self.lc_length
			    else:
				    promote_index = count + 1
		    count = count + 1
		phase_name = self.plans[promote_index]
		self.change(phase_name)

	def change(self, phase_name):
		#
		# set the phase to the phase ACL template
		#
		print "Change the phase to the phase ACL template"
		acl_template_name = self.plan_templates[phase_name]
		print "IMPLEMENTING: changing to phase: " + phase_name + " with template: " + acl_template_name
		self.bl_package_coord.replaceAclTemplate(self.bl_package_name,acl_template_name)
		self.setPhase(phase_name)

	def share(self, phase_name):
		#
		# 'append' the permissions to the new phase without removing old permissions
		#
		print "Change the phase to the phase ACL template"
		acl_template_name = self.plan_templates[phase_name]
		print "IMPLEMENTING: sharing to phase: " + phase_name + " with template: " + acl_template_name
		self.bl_package_coord.addAclTemplate(self.bl_package_name,acl_template_name)
		self.setPhase(phase_name)

	def getPhase(self):
		return self.bl_package_coord.getPackagePropertyValue(self.bl_package_name,self.plan_property)

	def setPhase(self,phase_name):
		return self.bl_package_coord.setPackagePropertyValue(self.bl_package_name,self.plan_property,phase_name)


# Utility Routines	

def encrypt(val):
	enc = base64.b64encode(val)
	enc = enc[::-1]
	enc = PRIVATE_PREFIX + base64.b64encode(enc)
	return enc

def decrypt(val):
	enc = val.replace(PRIVATE_PREFIX,"")
	enc = base64.decodestring(enc)
	enc = enc[::-1]
	enc = base64.decodestring(enc)
	enc = enc.replace(PRIVATE_PREFIX, "")
	return enc

def strip_private_flags(param_list):
	for item, val in param_list.items():
		if unicode(val,"utf-8").find(unicode(PRIVATE_PREFIX,"utf-8")) > -1:
			param_list[item] = decrypt(val)
	return param_list
	
