#!/usr/bin/jython
# coding=UTF-8
# ========================================================================
# LIBRARY NAME  : BLMANAGER.PY
# PURPOSE       :
#     Standardize and consolidate Bladelogic API calls into Classes.
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

from java.lang import Class

# ========================================================================
# BLADELOGIC
# ========================================================================

import bladelogic.cli.CLI as blcli
# from com.bladelogic.client import BRProfile

# ========================================================================
# BRPM
#    ACTION: update based on installation path
# ========================================================================

INSTALLATION_PATH=os.environ["_SS_APPPATH"]
LIBRARY_PATH=INSTALLATION_PATH + 'PYLIB'

sys.path.append(LIBRARY_PATH)

import common

"""
=======================================================================
NAME: BLConnectManager
PURPOSE:
    - Low level interactions with Bladelogic
=======================================================================
"""

class BLConnectManager:
	"Establish Foundational Bladelogic Controls"

	def __init__(self,bl_auth_profile,bl_role_name):
		#
		# assumes that the BL CREDENTIALS have been established
		#
		self.common = common.CommonManager()
		self.jli    = blcli.CLI()
		self.bl_auth_profile  = bl_auth_profile
		self.bl_role_name     = bl_role_name
		self.is_connected     = 0

	def getCommon(self):
		return self.common

	def connect(self):
		if self.is_connected == 0:
			self.jli.setServiceProfileName(self.bl_auth_profile)
			self.jli.setRoleName(self.bl_role_name)
			self.jli.connect()
			self.is_connected = 1

	def runBladelogicCmd(self,param_namespace,param_bl_command,param_args):
		cmd = []
		cmd.append(param_namespace)
		cmd.append(param_bl_command)
	
		data_type = str(type(param_args)).lower()

		if data_type.find('list') >= 0:
			for arg in param_args:
				cmd.append(str(arg))
		else:
			cmd.append(str(param_args))

		try:
			bl_result = self.jli.run(cmd)
			assert bl_result, str(cmd)
		except AssertionError,e:
			print e
		return bl_result

	def run(self,namespace,command,arg_args):
		var_results = self.runBladelogicCmd(namespace,command,arg_args)
		if var_results.success() == 0:
			self.common.printError('API Command Failed: ' + namespace + ' ' + command)
			self.common.printError('Error: ' + str(var_results.error))
			sys.exit(-1)
		return_value = var_results.returnValue
		return return_value
		
	def runBoolean(self,namespace,command,args):
		boolean_str = self.run(namespace,command,args)
		if str(boolean_str) == '1':
			return 1
		if str(boolean_str).lower() == 'true':
			return 1
		return 0

	def runIgnore(self,namespace,command,args):
		var_results = self.runBladelogicCmd(namespace,command,args)
		#if var_results.success() == 0:
		#	self.common.printError('Ignoring API Command Failed: ' + namespace + ' ' + command)
		#	self.common.printError('Error: ' + str(var_results.error))
		return_value = var_results.returnValue
		return return_value

	def runSuccess(self,namespace,command,args):
		var_results = self.runBladelogicCmd(namespace,command,args)
		if var_results.success():
			return 1
		return 0

	def runList(self,namespace,command,args):
		var_result = self.run(namespace,command,args)
		var_list = var_result.split('\n')
		var_list.remove('')
		return var_list

	def runExists(self,namespace,command,check_value):
		var_list = self.run(namespace,command,check_value)
		if check_value in var_list:
			return 1
		return 0

"""
=======================================================================
NAME: BLRBACCoordinator
PURPOSE:
    - Consolidate all RBAC activities and coordinate
=======================================================================
"""

class BLRBACCoordinator:
	"Coordinate all RBAC activities"

	def __init__(self, param_bl_connect_manager):
		self.bl_connect_mgr 	= param_bl_connect_manager
		self.bl_connect_mgr.connect()
		self.common		= self.bl_connect_mgr.getCommon()

	def getRoles(self):
		#
		# Get the role list
		#
		return self.bl_connect_mgr.run('RBACRole','getAllRoleNames',[])

	def getUsers(self):
		#
		# Get the user list
		#
		return self.bl_connect_mgr.run('RBACUser','getAllUserNames',[])

	def roleExists(self,role_name):
		return self.bl_connect_mgr.runExists('RBACRole','getAllRoleNames', role_name)

	def userExists(self,user_name):
		return self.bl_connect_mgr.runExists('RBACUser',
						     'getAllUserNames',
						     role_name)
	def getUsersByRoles(self,role_name):
		return self.bl_connect_mgr.run('RBACUser',
						'getAllUserNamesByRole',
						[role_name])

	def getRoleProperty(self,role_name,property_name):
		return self.bl_connect_mgr.run('RBACRole',
					       'getFullyResolvedPropertyValue',
					       [role_name,property_name])
	
	def createRole(self,role_name,role_desc,unix_user,windows_user):
		return self.bl_connect_mgr.run('RBACRole',
					       'createRole',
					       [role_name,role_desc,8,unix_user,windows_user])

	def createUser(self,user_name,password,description):
		var_result = self.bl_connect_mgr.run('RBACUser',
						     'createUser',
						     [user_name,password,description])

	def getUserProperty(self,user_name,property_name):
		property_value = self.bl_connect_mgr.run('RBACUser',
							 'getFullyResolvedPropertyValue',
							 [user_name,property_name])
		return str(property_value)

	def checkAuthProfileExists(self,auth_profile_name):
		return self.bl_connect_mgr.runSuccess('AuthorizationProfile',
						      'showAuthorizations',
						      [auth_profile_name])

	def getAuthProfileAuthorizations(self,auth_profile_name):
		#
		# Get the list of authorization profile authorizations
		#
		var_result = self.bl_connect_mgr.run('AuthorizationProfile',
						     'showAuthorizations',
						     [auth_profile_name])
		var_auth_list = var_result.split('\n')
		var_auth_list[len(var_auth_list)-1:] = []
		return var_auth_list

	def getAclTemplateNames(self):
		#
		# Get the list of authorization profile authorizations
		#
		var_template_name_list = []
		var_acl_template_list = []
		var_acl_template_list = self.bl_connect_mgr.runList('BlAclTemplate',
								    'listAllAclTemplates')
		for var_acl_template in var_acl_template_list:
			if var_acl_template.startswith('Name: ') == 1:
				acl_template_entry = var_acl_template.strip('Name: ')
				var_template_name_list.append(acl_template_entry)
		return var_template_name_list

	#
	# - create acl template if it doesn't exist
	#
	def generateAclTemplate(self,arg_acl_template_name,description):
		acl_template_list = self.getAclTemplateNames()
		if not arg_acl_template_name in acl_template_list:
			self.createAclTemplate(arg_acl_template_name,description)	

	def createAclTemplate(self,arg_acl_template_name,arg_description):
		return self.bl_connect_mgr.runSuccess('BLAclTemplate',
						      'createAclTemplate',
						      [arg_acl_template_name, arg_description])

	def recreateAclTemplate(self,arg_acl_template_name,arg_description):
		var_success = self.createAclTemplate(arg_acl_template_name,arg_description)
		if var_success == 0:
			var_success = self.deleteAclTemplate(arg_acl_template_name)
			var_success = self.createAclTemplate(arg_acl_template_name,arg_description)
	
	def deleteAclTemplate(self,arg_acl_template_name):
		varResult = self.bl_connect_mgr.run('BlAclTemplate',
						    'deleteAclTemplateByName',
						    [arg_acl_template_name])

	def addAclTemplateAuthProfile(self,arg_acl_template_name,arg_role_name,arg_authorization_profile):
		varResult = self.bl_connect_mgr.run('BlAclTemplate',
						    'addTemplatePermissionProfile',
						    [arg_acl_template_name, arg_role_name, arg_authorization_profile])

	def createAclTemplateWithProfile(self,arg_acl_template_name,arg_role_name,arg_auth_profile,arg_description):
		self.generateAclTemplate(arg_acl_template_name,arg_description)
		self.addAclTemplateAuthProfile(arg_acl_template_name,arg_role_name,arg_auth_profile)

	def addAclTemplatePermission (self,argACLTemplateName, argRoleName, argAuthorization):
		varResult = self.bl_connect_mgr.run('BlAclTemplate',
						    'addTemplatePermission',
						    [argACLTemplateName, argRoleName, argAuthorization])
			
	def addAclTemplateReadOnlyProfile(self,acl_template_name,arg_role_name):
		self.addAclTemplatePermission(acl_template_name,arg_role_name,'DepotFolder.Read')
		self.addAclTemplatePermission(acl_template_name,arg_role_name,'ComponentTemplateFolder.Read')
		self.addAclTemplatePermission(acl_template_name,arg_role_name,'JobFolder.Read')
		self.addAclTemplatePermission(acl_template_name,arg_role_name,'ComponentGroup.Read')		
		
	def addAuthProfileToRole(self,arg_role_name,arg_profile_name):
		return self.bl_connect_mgr.runSuccess('RBACRole',
						      'addAuthProfileToRoleByName',
						      [arg_role_name, arg_profile_name])

	def addDefaultAclTemplateToRole(self,arg_role_name,arg_acl_template):
		return self.bl_connect_mgr.runSuccess('RBACRole',
						      'setDefaultAclTemplateByName',
						      [arg_role_name, arg_acl_template])

	def appendAclPolicyToAclTemplate(self,arg_acl_template,arg_acl_policy):
		self.common.printError('No support to add ACL Policy to ACL Template')

	def getServerGroupServers(self,server_group):
		return self.bl_connect_mgr.runList('Server',
						   'listServersInGroup',
						   [server_group])

	def replaceServerTemplate(self,acl_template_name,server_group):
		#
		# adds server permissions based on the ACL template
		#
		group_server_list = self.getServerGroupServers(server_group)
		for group_server in group_server_list:
			var_result = self.bl_connect_mgr.run('Server',
							     'applyAclTemplate',
							     [group_server,acl_template_name,"true"])

	def appendServerTemplate(self,acl_template_name,server_group):
		#
		# adds server permissions based on the ACL template
		#
		group_server_list = self.getServerGroupServers(server_group)
		for group_server in group_server_list:
			var_result = self.bl_connect_mgr.run('Server',
							     'applyAclTemplate',
							     [group_server,acl_template_name,"0"])

	def assignRoleProperties(self,role_name,property_dict):
		for property in property_dict.keys():
			if property in self.role_property_list:
				#
				# assign the value to the role
				#
				property_value = property_dict[property]
				self.assignRolePropertyValue(role_name,property,property_value)

	def assignRolePropertyValue(self,argRoleName, argRoleProperty, argValue):
		return self.bl_connect_mgr.runSuccess('RBACRole',
						      'setPropertyValueByName',
						      [argRoleName, argRoleProperty, argValue])

	def assignUserPropertyValue(self,argUserName, argUserProperty, argValue):
		return self.bl_connect_mgr.runSuccess('RBACUser',
						      'setPropertyValueByName',
						      [argUserName, argUserProperty, argValue])
		
	def createACLPolicy(self,acl_policy_name,description):
		varResult = self.bl_connect_mgr.run('BlAclPolicy',
						    'createAclPolicy',
						    [acl_policy_name,description])

	#
	# Name: getAclPolicyPermissions
	# Purpose:
	#	- Extract out the policy permissions for the associated ACL policy.
	#	- Use the information to avoid assigning permissions already assigned
	#
	def getAclPolicyPermissions(self,acl_policy_name):
		var_acl_policy_data = self.bl_connect_mgr.run('BlAclPolicy',
							      'showPolicyPermissions',
							      [acl_policy_name])
		var_acl_policy_list = var_acl_policy_data.split('\n')
		for acl_policy_perm in var_acl_policy_list:
			if acl_policy_perm <> '':
				policy_tokens = acl_policy_perm.split('\t')
				role_name = policy_tokens[0]
				perm_name = policy_tokens[1]
				if role_name in acl_policy_permissions_dict.keys():
					#
					# get the list and append
					#
					perm_list = acl_policy_permissions_dict[role_name]
					perm_list.append(perm_name)
				else:
					new_perm_list = []
					new_perm_list.append(perm_name)
					acl_policy_permissions_dict[role_name] = new_perm_list
		return acl_policy_permissions_dict

	#
	# Name: applyServerAclTemplateToAclPolicy
	# Purpose:
	#	- apply SERVER ACLs template to the ACL Policy
	#
	def applyServerAclTemplateToAclPolicy(self,acl_policy_name,acl_template_name):
		#
		# there is no command to add ACL template permissions to a policy. The result is that you
		# need to "reverse engineer" the acl_template permissions and the underlying AUTH_PROFILES
		# to get the system permissions and then add it to the policy.
		#
		acl_policy_permission_dict = self.getAclPolicyPermissions(acl_policy_name)
		acl_role_auth_dict = self.getPermissionsFromAclTemplate(acl_template_name)
		for role_name in acl_role_auth_dict.keys():
			self.common.printInfo('   Role: ' + role_name)
			role_perm_list = [ ]
			if role_name in acl_policy_permission_dict.keys():
				role_perm_list = acl_policy_permission_dict
			auth_list = acl_role_auth_dict[role_name]
			for auth_name in auth_list:
				if auth_name in role_perm_list:
					continue
				if auth_name.startswith('Server.') == 0:
					if auth_name.startswith('ServerGroup.') == 0:
						continue
				varResult = self.bl_connect_mgr.run('BlAclPolicy',
								    'addPolicyPermission',
								    [acl_policy_name,role_name,auth_name])

	#
	# Name: applyAclTemplateToAclPolicy
	# Purpose:
	#	- apply ACL template to the ACL Policy
	#
	def applyAclTemplateToAclPolicy(self,acl_policy_name,acl_template_name):
		#
		# there is no command to add ACL template permissions to a policy. The result is that you
		# need to "reverse engineer" the acl_template permissions and the underlying AUTH_PROFILES
		# to get the system permissions and then add it to the policy.
		#
		acl_policy_permission_dict = self.getAclPolicyPermissions(acl_policy_name)
		acl_role_auth_dict = self.getPermissionsFromAclTemplate(acl_template_name)
		for role_name in acl_role_auth_dict.keys():
			role_perm_list = [ ]
			if role_name in acl_policy_permission_dict.keys():
				role_perm_list = acl_policy_permission_dict
			auth_list = acl_role_auth_dict[role_name]
			for auth_name in auth_list:
				if auth_name in role_perm_list:
					continue
				#
				# Do not add server perms for these ACLs since it should never be used here
				#
				if auth_name.startswith('Server.') == 1:
					continue					
				varResult = self.bl_connect_mgr.run('BlAclPolicy',
								    'addPolicyPermission',
								    [acl_policy_name,role_name,auth_name])

	#
	# Name: applyPolicyPermission
	# Purpose: encapsulate adding of policy permissions
	#
	def applyPolicyPermission(self,acl_policy_name,role_name,auth_name):
		varResult = self.bl_connect_mgr.run('BlAclPolicy',
						    'addPolicyPermission',
						    [acl_policy_name,role_name,auth_name])
	
	#
	# Name: getPolicyPermissionFromAclTemplate
	# Purpose:
	#	- reverse engineer the permissions in an ACL template
	#	- requires additionally to go through authorization profiles as well
	#
	
	def getPermissionsFromAclTemplate(self,acl_template_name):
		#
		# get through the ACL template per permission
		#
		role_auth_dict = { }
		#
		#
		#
		var_template_perm_list = self.bl_connect_mgr.runList('BlAclTemplate',
								     'showTemplatePermissions',
								     [acl_template_name])
		#	
		# parse through the result set and figure out how to manage it
		#
		for var_template_line in var_template_perm_list:
			#
			# it could be a system permission, profile, or policy list
			#
			if var_template_line.startswith('Policy Name'):
				continue
			else:
				if var_template_line.startswith('End of Policy'):
					continue
			var_template_tokens = var_template_line.split('\t')
			role_name = var_template_tokens[0]
			auth_name = var_template_tokens[1]
			if var_template_line.endswith(' (profile)'):
				#
				# extract out the profile name and pull permissions
				#
				auth_name = auth_name[:-10]
				auth_profile_list = self.getAuthProfileAuthorizations(auth_name)
				#		
				# append the auth_profile_list to the existing role list
				#
				if role_name in role_auth_dict.keys():
					auth_list = role_auth_dict[role_name]
					auth_list.extend(auth_profile_list)
				else:
					role_auth_dict[role_name] = auth_profile_list
			else:
				#
				# append the system authorization to the existing role list
				#

				if role_name in role_auth_dict.keys():
					auth_list = role_auth_dict[role_name]
					auth_list.append(auth_name)
				else:
					role_auth_list = [ ]
					role_auth_list.append(auth_name)
					role_auth_dict[role_name] = role_auth_list
		return role_auth_dict

"""
=======================================================================
NAME: BLComponentCoordinator
PURPOSE:
  - Manage component templates and components under only class
  - Requires a BL Connection Object
=======================================================================
"""

class BLComponentCoordinator:
	"Manage Components and Coordinate Activities"

	def __init__(self,bl_connect_manager):
		self.bl_connect_mgr 	= bl_connect_manager
		self.bl_connect_mgr.connect()
		self.common		= self.bl_connect_mgr.getCommon()

	def existsTemplateGroup(self,param_folder_name):
		ret_value = self.bl_connect_mgr.runBoolean('TemplateGroup','groupExists',param_folder_name)
		return ret_value
	
	def renameTemplateGroup(self,param_group_name,param_old_child,param_new_child):
		self.common.printError('RENAMING TEMPLATE GROUPS NOT SUPPORTED')
	
	def createTemplateGroupFromBase(self,param_base,param_part):
		self.common.printInfo('Creating: ' + param_base + '/' + param_part)
		base_parent_id = self.getTemplateGroupId(param_base)
		base_part_id = self.bl_connect_mgr.run('TemplateGroup','createTemplateGroup',[param_part,base_parent_id])

	def getTemplateGroupId(self,param_group_name):
		return self.bl_connect_mgr.run('TemplateGroup','groupNameToId',param_group_name)
	
	def createTemplateGroup(self,param_folder_name):
		if self.existsTemplateGroup(param_folder_name) == 1:
			return
		#
		# generate the template group
		#
		group_parts = param_folder_name.split('/')
		current_group = ''
		for part in group_parts:
			if part == '':
				continue
			base_group = current_group
			if base_group =='':
				base_group = '/'
			current_group = current_group + '/' + part
			if self.existsTemplateGroup(current_group) == 1:
				continue
			else:
				self.createTemplateGroupFromBase(base_group,part)	
		return

	def existsTemplate(self,param_group_name,param_template_name):
		#
		# check to see if the template exists.
		#	Template listAllByGroup
		#
		group_id = self.getTemplateGroupId(param_group_name)
		template_list = self.bl_connect_mgr.runList('Template','listAllByGroup',[group_id])
		if param_template_name in template_list:
			return 1
		return 0
	
	def createTemplate(self,param_group_name,param_template_name):
		self.createTemplateGroup(param_group_name)
		#
		# generate the component template
		#
		#
		# If the component exists, then ignore processing here, print warning
		#
		if self.existsTemplate(param_group_name,param_template_name) == 0:
			self.common.printInfo('Create Empty Template: ' + param_template_name)
			group_id = self.getTemplateGroupId(param_group_name)
			return self.bl_connect_mgr.run('Template',
											'createEmptyTemplate',
										[param_template_name, group_id,'true'])
		else:
			self.common.printInfo('Template Exists: ' + param_group_name + '/' + param_template_name)

	def mapPrimitiveType(self,param_type):
		if param_type.find('Primitive') > 0:
			return param_type
		#
		# remap to 3 different 
		#
		if param_type == '':
			return 'Primitive:/String'
		if param_type.lower() == 'string':
			return 'Primitive:/String'
		if param_type.lower() == 'integer':
			return 'Primitive:/Integer'
		if param_type.lower() == 'date':
			return 'Primitive:/Date'
		if param_type.lower() == 'boolean':
			return 'Primitive:/Boolean'
		if param_type.lower() == 'decimal':
			return 'Primitive:/Decimal'
		return 'Primitive:/String'
		

	def addParameterToTemplate(self,param_group_name,param_template_name,param_prop_name,param_prop_desc,param_prop_type,param_editable,param_required,param_default_val):
		var_template_name = param_template_name
		var_group_name = param_group_name
		var_prop_name = param_prop_name
		var_prop_desc = param_prop_desc
		var_prop_type = self.mapPrimitiveType(param_prop_type)
		var_editable = param_editable
		var_required = param_required
		var_default_val = param_default_val
		return self.bl_connect_mgr.runIgnore('Template',
									'addLocalParameter',
									[var_template_name,
									var_group_name,
									var_prop_name,
									var_prop_desc,
									var_prop_type,
									var_editable,
									var_required,
									var_default_val])	

	def removeTemplate(self,param_group_name,param_template_name):
		self.common.printInfo('TO DO: removeTemplate')
	
	def removeTemplatesFromGroup(self,param_group_name):
		self.common.printInfo('TO DO: removeTemplatesFromGroup')
		
	def removeTemplateTree(self,param_group_name):
		self.common.printInfo('TO DO: removeTemplateTree')

	def createComponentGroup(self,group_name):
		if self.existsComponentGroup(group_name) == 1:
			return
		#
		# generate a component group
		#
		group_parts = group_name.split('/')
		current_group = ''
		for part in group_parts:
			if part == '':
				continue
			base_group = current_group
			if base_group =='':
				base_group = '/'
			current_group = current_group + '/' + part
			if self.existsComponentGroup(current_group) == 1:
				continue
			else:
				self.createComponentGroupFromBase(base_group,part)	
		return

	def existsComponentGroup(self,param_folder_name):
		#ret_value = self.bl_connect_mgr.runBoolean('ComponentGroup','groupExists',param_folder_name)
		self.common.printError('COMMAND NOT AVAILABLE TO FIND COMPONENT GROUP')
		return 1
	
	def createComponentGroupFromBase(self,param_base,param_part):
		self.common.printInfo('Creating: ' + param_base + '/' + param_part)
		self.common.printError('COMMAND NOT AVAILABLE TO CREATE COMPONENT GROUP')
		
	def getComponentGroupId(self,param_group_name):
		return self.bl_connect_mgr.run('ComponentGroup','groupNameToId',param_group_name)

	def createComponent(self,component_name, component_path, template_name, server_name):
		template_db_key = self.bl_connect_mgr.run('Template','getDBKeyByGroupAndName',[component_path,template_name])
		device_id = self.bl_connect_mgr.run('Server','getServerIdByName',server_name)
		return self.bl_connect_mgr.run('Component','createComponent',[component_name,template_db_key,device_id])				

	def createComponentWithProperty(self,component_name, component_path, template_name, server_name, gproperty_handle):
		template_db_key = self.bl_connect_mgr.run('Template','getDBKeyByGroupAndName',[component_path,template_name])
		device_id = self.bl_connect_mgr.run('Server','getServerIdByName',server_name)
		instance_name = findpropertyinstance()
		return self.bl_connect_mgr.run('Component','createComponentWithPropertyInstance',[component_name,template_db_key,device_id, instance_name])				

	def getComponentKeysInTemplate(self,group_name,template_name):
		template_db_key = self.bl_connect_mgr.run('Template','getDBKeyByGroupAndName',[group_name,template_name])
		component_key_list = self.bl_connect_mgr.runList('Component','getAllComponentKeysByTemplateKey',[template_db_key])
		return component_key_list

	def getComponentKeyByName(self,group_name,template_name,component_name):
		key_list = self.getComponentKeysInTemplate(group_name,template_name)
		for key in key_list:
			compname = self.bl_connect_mgr.run('Component','componentKeyToName',key)
			if(compname == component_name):
				return key
		return "key_not_found"


	def existsPackage(self,package_group,package_name):
		package_list = self.bl_connect_mgr.runList('DepotObject',
													'listAllByGroup',
													[package_group])
		if package_name in package_list:
			return 1
		return 0
	
	def appendPackage(self,package_group,package_name,component_key,options={}):
		#
		# 1. create a new package if it doesn't exist
		# 2. otherwise, append the component
		#
		depot_group_id = self.bl_connect_mgr.run('DepotGroup','groupNameToId',[package_group])
		bSoftLinked="false"
		if options.has_key("bSoftLinked"):
		  bSoftLinked=options["bSoftLinked"]
		bCollectFileAcl="false"
		if options.has_key("bCollectFileAcl"):
		  bCollectFileAcl=options["bCollectFileAcl"]
		bCollectFileAttributes="false"
		if options.has_key("bCollectFileAttributes"):
		  bCollectFileAttributes=options["bCollectFileAttributes"]
		bCopyFileContents="true"
		if options.has_key("bCopyFileContents"):
		  bCopyFileContents=options["bCopyFileContents"]
		bCollectRegistryAcl="false"
		if options.has_key("bCollectRegistryAcl"):
		  bCollectRegistryAcl=options["bCollectRegistryAcl"]
		#
		# parameters to create the package
		#
		if self.existsPackage(package_group,package_name) == 0:
			#
			# create the package here ...
			#
			# Name of the package.
			#
			self.bl_connect_mgr.run('BlPackage',
								'createPackageFromComponent',
								[package_name,
								depot_group_id,
								bSoftLinked,
								bCollectFileAcl,
								bCollectFileAttributes,
								bCopyFileContents,
								bCollectRegistryAcl,
								component_key])
		else:
			#
			# add the package here ...
			#
			self.bl_connect_mgr.run('BlPackage',
								'importComponentToPackage',
								[package_group,
								package_name,
								bSoftLinked,
								bCollectFileAcl,
								bCollectFileAttributes,
								bCopyFileContents,
								bCollectRegistryAcl,
								component_key,"",""])		

	
"""
=======================================================================
	Name: BLPropertyCoordinator
	Purpose:
		- Manages all property dictionary activities
		- Requires a BL Connection Object
=======================================================================
"""

class BLPropertyCoordinator:
	"Coodinates activities with "

	def __init__(self,bl_connect_manager):
		self.bl_connect_mgr = bl_connect_manager
		self.bl_connect_mgr.connect()
		self.canonical_base = 'Class://SystemObject/'

	def getCanonicalBase(self):
		return self.canonical_base
	
	def returnCanonicalClassName(self, param_class_name):
		if param_class_name.startswith('Class://SystemObject') == 0:
			param_class_name = (self.canonical_base + param_class_name)
			if param_class_name[-1] == "/":
				params_class_name = param_class_name[0:-1]
		return param_class_name
	
	def getBLPropertyClass(self,class_name):
		return BLPropertyClass(self, self.bl_connect_mgr,class_name)

	def createBLPropertyClass(self,class_name,class_desc):
		return self.createBLPropertySubClass(self.canonical_base,class_name,class_desc)

	def createBLPropertySubClass(self,class_name,sub_class_name,class_desc):
		var_result = self.bl_connect_mgr.run('PropertyClass',
						     'createSubClass',
						     [class_name,sub_class_name,class_desc])
		var_property_class_name = class_name + '/' + sub_class_name
		return self.getBLPropertyClass(var_property_class_name)

	def validateClassName(arg_property_class):
		return self.bl_connect_mgr.runSuccess('PropertyClass',
						      'isPropertyClassDefined',
						      [arg_property_class])

	def getClassNames(self, param_class_name):
		results = self.bl_connect_mgr.run('PropertyClass', 'listAllSubclassNames',[param_class_name])
		results = results.replace(self.canonical_base, "")
		if results[-2:len(results)] == "\n\n":
			results = results[0:-1]
		results_arr = results.split("\n")
		return results_arr

	def getClassNamesFromRoot(self,param_class_name):
		full_class_name = self.canonical_base + param_class_name
		return self.getClassNames(full_class_name)

"""
=======================================================================
	Name: BLPropertyClass
	Purpose:
		- Manages a single class instance
=======================================================================
"""

class BLPropertyClass:
	"Manages a single class and its instances"

	def __init__(self,bl_property_coordinator, bl_connect_manager,class_name):
		self.bl_connect_mgr = bl_connect_manager
		self.bl_connect_mgr.connect()
		self.coordinator = bl_property_coordinator
		self.class_name = self.coordinator.returnCanonicalClassName(class_name)

	def getClassName(self):
		return self.class_name
 
	def attachProperty(self,arg_property, arg_desc, arg_type, arg_edit, arg_req, arg_default_value):
		var_edit = 'false'
		if arg_edit == 1:
			var_edit = 'true'
		var_req = 'false'
		if arg_req == 1:
			var_req = 'true'
		return self.bl_connect_mgr.run('PropertyClass',
					       'addProperty',
					       [self.class_name,
						arg_property,
						arg_desc,
						arg_type,
						var_edit,
						var_req,
						arg_default_value])


	def attachStringProperty(self,arg_property,arg_desc,arg_edit,arg_req,arg_default_value):
		return self.attachProperty(arg_property,
					   arg_desc,
					   'Primitive:/String',
					   arg_edit,
					   arg_req,
					   arg_default_value)

	def attachBooleanProperty(self,arg_property,arg_desc,arg_edit,arg_req,arg_default_value):
		return self.attachProperty(arg_property,
					   arg_desc,
					   'Primitive:/Boolean',
					   arg_edit,
					   arg_req,
					   arg_default_value)

	def attachStrenumProperty(self, arg_property, arg_desc, arg_enum_dict, arg_default_value, arg_edit, arg_req):
		var_edit = 'false'
		if arg_edit == 1:
			var_edit = 'true'
		var_req = 'false'
		if arg_req == 1:
			var_req = 'true'
		#
		# Generate the enum string list which are the potential values of this drop-down
		#
		enum_name_list_str = ''
		enum_value_list_str = ''
		for name in arg_enum_dict.keys():
			value = arg_enum_dict[name]
			enum_name_list_str = enum_name_list_str + '\"' + name + '\",'
			enum_value_list_str = enum_value_list_str + '\"' + name + '\",'
		#
		# remove any trailing ','
		#
		enum_name_list_str = enum_name_list_str.rstrip(',')
		enum_value_list_str = enum_value_list_str.rstrip(',')

		return self.bl_connect_mgr.run('PropertyClass',
					       'addStringEnumProperty',
					       [self.class_name,
						arg_property,
						arg_desc,
						var_edit,
						var_req,
						enum_name_list_str,
						enum_value_list_str,
						arg_default_value])


	def provideInstanceName(self,arg_instance_name):
		if arg_instance_name.startswith(self.class_name) == 1:
			return arg_instance_name
		return self.class_name + '/' + arg_instance_name		
				
	def getPropertyNames(self):
		return self.bl_connect_mgr.runList('PropertyClass',
						   'listAllPropertyNames',
						   [self.class_name])
	
	def getInstanceNames(self):
		return self.bl_connect_mgr.runList('PropertyClass',
						   'listAllInstanceNames',
						   [self.class_name])

	def getInstances(self):
		#
		# reads in all the instances and reads in each property name and value
		#
		var_bl_instance_list = self.getInstanceNames()
		var_property_instance_dict = { }
		for var_instance in var_bl_instance_list:
			#
			# Property Name = Value List
			#
			var_prop_name_value_dict = { }
			var_prop_name_value_dict = self.getInstancePropertyValues(var_instance)
			var_property_instance_dict[var_instance] = var_prop_name_value_dict
		return var_property_instance_dict

	def getInstancePropertyValues(self,arg_property_instance_name):
		#
		# reads in all the instances and reads in each property name and value
		#
		var_property_instance_name = self.provideInstanceName(arg_property_instance_name)
		var_bl_instance_list = self.bl_connect_mgr.runList('PropertyInstance',
								   'listAllPropertyValues',
								   var_property_instance_name)
		var_property_name_value_dict = { }
		for name_value_pair in var_bl_instance_list:
			tokens = name_value_pair.split('=')
			if len(tokens) == 2:
				var_name	= tokens[0].strip()
				var_value	= tokens[1].strip()
				var_property_name_value_dict[var_name] = var_value
		return var_property_name_value_dict

	def getInstancePropertyValue(self,arg_property_instance_name,arg_property_name):
		var_prop_instance_name = self.provideInstanceName(arg_property_instance_name)
		return self.bl_connect_mgr.run('PropertyInstance',
					       'getPropertyValue',
					       [var_prop_instance_name, arg_property_name])

	def setInstancePropertyValue(self,arg_property_instance_name,arg_property_name,arg_value):
		return self.updateInstancePropertyValue(arg_property_instance_name,arg_property_name,arg_value)

	def instanceExists(self,arg_property_instance_name):
		return self.bl_connect_mgr.run('PropertyClass',
					       'isPropertyClassInstanceDefined',
					       [self.class_name, arg_property_instance_name])

	def createInstance(self,arg_property_instance_name, arg_prop_description):
		return self.bl_connect_mgr.run('PropertyInstance',
					       'createInstance',
					       [self.class_name,
						arg_property_instance_name,
						arg_prop_description])

	def deleteInstance(self,arg_property_instance_name,arg_force):
		var_prop_instance_name = self.provideInstanceName(arg_property_instance_name)
		return self.bl_connect_mgr.runIgnore('PropertyInstance',
						     'deleteInstance',
						     [var_prop_instance_name,arg_force])

	def updateInstanceProperties(self,arg_property_instance_name, arg_property_value_dict):
		for var_prop_name in arg_property_value_dict.keys():
			var_prop_value = arg_property_value_dict[var_prop_name]
			self.updateInstancePropertyValue(arg_property_instance_name,
							 var_prop_name,
							 var_prop_value)

	def updateInstancePropertyValue(self,arg_property_instance_name,arg_prop_name,arg_prop_value):
		var_prop_instance_name = self.provideInstanceName(arg_property_instance_name)
		var_result = self.bl_connect_mgr.run('PropertyInstance',
						     'setOverriddenValue',
						     [var_prop_instance_name,arg_prop_name,arg_prop_value])

	def createInstanceAndLoad(self,arg_property_instance_name,arg_prop_description,arg_property_value_dict):
		var_prop_instance_name = self.provideInstanceName(arg_property_instance_name)
		var_return_value = self.createInstance(var_prop_instance_name,arg_prop_description)
		self.updateInstanceProperties(var_prop_instance_name,arg_property_value_dict)

"""
=======================================================================
	Name: BLServerCoordinator
	Purpose:
		- Manage Servers
		- Manage Server Groups / Smart Groups
=======================================================================
"""

class BLServerCoordinator:
	"Coordinates the management of Servers in Bladelogic"

	def __init__(self,bl_connect_manager):
		self.bl_connect_mgr    = bl_connect_manager
		self.common	   = self.bl_connect_mgr.getCommon()
		self.bl_connect_mgr.connect()

	def groupExists(self,group_name):
		var_folder_name = group_name

		if var_folder_name.startswith('/') == 0:
			# append the '/' to the name
			var_folder_name = '/' + var_folder_name
		words = var_folder_name.split('/')
	
		folder_name_check = '/'
		last_list = [ ]

		for word in words:
			if word != '':
				if (word in last_list) == 0:
					return 0
			folder_name_check = folder_name_check + word
			last_list = self.bl_connect_mgr.runList('ServerGroup',
								'listChildGroupsInGroup',
								[folder_name_check])
			if word != '':
				folder_name_check = folder_name_check + '/'
		return 1
		
	def getGroupFolderName(self,base_group_name,group_name):
		if base_group_name.startswith('/') == 0:
			# append the '/' to the name
			base_group_name = '/' + base_group_name
		return base_group_name + '/' + group_name	
		
	def groupExistsOnBase(self,base_group_name,group_name):
		group_folder_name = self.getGroupFolderName(base_group_name,group_name)
		if self.groupExists(group_folder_name) == 1:
			return 1
		return 0

	def createGroup(self,base_group_name, group_name):
		if base_group_name.startswith('/') == 0:
			# append the '/' to the name
			base_group_name = '/' + base_group_name
			
		if self.groupExistsOnBase(base_group_name,group_name) == 1:
			return self.getGroupFolderName(base_group_name,group_name)
		
		var_parent_base_id = self.bl_connect_mgr.run('ServerGroup',
							     'groupNameToId',
							     [base_group_name])
		var_result = self.bl_connect_mgr.run('StaticServerGroup',
						     'createGroupWithParentName',
						     [group_name, base_group_name])
		return self.getGroupFolderName(base_group_name,group_name)


	def createSmartGroup(self,base_group_name,group_name,arg_desc,arg_property,arg_condition,arg_property_value):
		#
		# returns the name of the smart group
		#
		if base_group_name.startswith('/') == 0:
			# append the '/' to the name
			base_group_name = '/' + base_group_name

		if self.groupExistsOnBase(base_group_name,group_name) == 1:
			return self.getGroupFolderName(base_group_name,group_name)

		var_server_group_name = base_group_name + '/' + group_name
		var_result = self.bl_connect_mgr.run('SmartServerGroup',
						     'createGroup',
						     [base_group_name,
						      group_name,
						      arg_desc,
						      arg_property,
						      arg_condition,
						      arg_property_value])
		return var_server_group_name

	def setSmartGroupToMatchall(self,group_name):
		return self.bl_connect_mgr.run('SmartServerGroup', 'setMatchAll', [group_name, 'true'])
	
	def getServersFromGroup(self,group_name):
		#group_id = self.bl_connect_mgr.run('ServerGroup', 'groupNameToId', [group_name])
		return self.bl_connect_mgr.runList('Server', 'listServersInGroup', [group_name])
			
	def refreshSmartGroup(self,group_name,arg_desc):
		group_id = self.bl_connect_mgr.runBladelogicCmd('ServerGroup', 'groupNameToId', [group_name])
		var_results = self.bl_connect_mgr.run('SmartServerGroup', 'setDescription', [group_id,arg_desc])

	def addSmartGroupProperty(self,base_group_name, arg_property, arg_operator, arg_property_value):
		if base_group_name.startswith('/') == 0:
			# append the '/' to the name
			base_group_name = '/' + base_group_name
		var_result = self.bl_connect_mgr.run('SmartServerGroup',
						     'addCondition',
						     [base_group_name, arg_property, arg_operator, arg_property_value])

	def applyAclPolicy(self,server_name,policy_name):
		return self.bl_connect_mgr.run('Server', 'applyAclPolicy', [server_name, policy_name])

	def applyGroupACLPolicy(self,group_name,policy_name):
		return self.bl_connect_mgr.run('ServerGroup', 'applyAclPolicy', [group_name, policy_name])

	def getServerPolicies(self,server_name):
		policy_names = [ ]
		var_perm_list = self.bl_connect_mgr.runList('Server', 'showPermissions', [server_name])
		for perm_line in var_perm_list:
			if perm_line.startswith('Policy Name: '):
				policy_name = perm_line[13:]
				policy_names.append(policy_name)
		return policy_names

	def getServerPropertyValue(self,arg_server_name,arg_property):
		return self.bl_connect_mgr.run('Server',
					       'getFullyResolvedPropertyValue',
					       [arg_server_name, arg_property])

	def setServerPropertyValue(self,arg_server_name,arg_property, arg_property_value):
		return self.bl_connect_mgr.runIgnore('Server',
						     'setPropertyValueByName',
						     [arg_server_name, arg_property, arg_property_value])

	def setServerGroupPropertyValue(self,arg_server_group,arg_property, arg_property_value):
		#
		# no quick way to update the properties for a full list of servers
		#
		server_list = self.getServersFromGroup(arg_server_group)
		for server in server_list:
			self.setServerPropertyValue(server_name,arg_property,arg_property_value)

	def addPropertyStringList(self,arg_server_name,arg_property, arg_str_pattern):
		property_list_str = self.getServerPropertyValue(arg_server_name,arg_property)
		# if an empty string, then remove all whitespace characters
		property_list_str = property_list_str.lstrip()
		#
		# look for the string pattern in the list, if it is there, ignore, otherwise
		# append
		#
		pattern_index = property_list_str.find(arg_str_pattern)
		if pattern_index == -1:
			#
			# not found, append to the string or create string if it is empty
			#
			if property_list_str == '':
				property_list_str = arg_str_pattern
			else:
				property_list_str = property_list_str + ',' + arg_str_pattern
			self.setServerPropertyValue(arg_server_name,arg_property,property_list_str)


	def getServerNames(self):
		#
		# Get the server list
		#
		return self.bl_connect_mgr.runList('Server','listAllServers',[])

	def getServerProperties(self):
		server_properties_dict = { }
		var_server_list = self.getServerNames()
		for server_name in var_server_list:
			if server_name != '':
				server_properties_dict[server_name] = self.getSingleFullProperties(server_name)
		self.common.printInfo('Complete server properties processing')
		return server_properties_dict

	def getSingleServerProperties(self,server_name):
		property_value_dict = { }
		for property_name in self.server_property_list:
			property_value_dict[property_name] = self.getServerProperty(server_name,property_name)
		return property_value_dict

	def getShowProperties(self,server_name):
		return self.bl_connect_mgr.run('Server','printAllProperties',[server_name])
	
	def getSingleFullProperties(self,server_name):
		property_value_dict = { }
		property_value_list = [ ]
		property_value_list = self.bl_connect_mgr.runList('Server','printAllProperties',[server_name])
		key_value_array = [ ]
		for key_value in property_value_list:
			key_value_array = key_value.split(' = ')
			if len(key_value_array) == 2:
				key = key_value_array[0]
				value = key_value_array[1]
				property_value_dict[key] = value
			else:
				if len(key_value_array) == 1:
					property_value_dict[key] = ''
		return property_value_dict
			
	def getServerProperty(self,server_name,property_name):
		return self.bl_connect_mgr.run('Server','getFullyResolvedPropertyValue',[server_name,property_name])

	def getSingleServerRoles(self,server_name):
		server_roles_dict = self.getSingleServerRolesDict(server_name)
		name_key_list = server_roles_dict.keys()
		name_key_list.sort()
		return name_key_list

	def getShowPermissions(self,server_name):
		var_result = self.bl_connect_mgr.run('Server','showPermissions',[server_name])
		return str(var_result)
		
	def getSingleServerRolesDict(self,server_name):
		#
		# server roles
		#
		bl_acl = self.bl_connect_mgr.run('Server','showPermissions',[server_name])
		bl_acl_str	= str(bl_acl)
		bl_acl_list = bl_acl_str.split('\n')
		#
		# returns the list of roles and authorizations
		#
		#	auth[role] = list of authorization
		#
		bl_acl_role_perm_dict = { }
		for bl_acl_entry in bl_acl_list:
			bl_acl_entry_list = bl_acl_entry.split('\t')
			if len(bl_acl_entry_list) == 2:
				bl_acl_name	= bl_acl_entry_list[0]
				bl_acl_auth = bl_acl_entry_list[1]
				if bl_acl_name in bl_acl_role_perm_dict:
					bl_acl_perm_list = bl_acl_role_perm_dict[bl_acl_name]
					bl_acl_perm_list.append(bl_acl_auth)
				else:
					bl_acl_perm_list = [ ]
					bl_acl_perm_list.append(bl_acl_auth)
					bl_acl_role_perm_dict[bl_acl_name] = bl_acl_perm_list
		
		name_key_list = bl_acl_role_perm_dict.keys()
		for role_name in name_key_list:
			bl_acl_perm_list = bl_acl_role_perm_dict[role_name]
			bl_acl_perm_list.sort()
			bl_acl_role_perm_dict[role_name] = bl_acl_perm_list
		return bl_acl_role_perm_dict

	def getServerRoles(self):
		server_roles_dict = { }
		server_list = self.getServerNames()
		for server_name in server_list:
			server_role_list = self.getSingleServerRoles(server_name)
			for role_name in server_role_list:
				server_instance_dict = { }
				server_instance_name = server_name + '_' + role_name
				server_instance_dict['server_name'] = server_name
				server_instance_dict['role_name'] = role_name
				server_roles_dict[server_instance_name] = server_instance_dict
			count = count + 1
		return server_roles_dict
		
"""
=======================================================================
	Name: BLDepotCoordinator
	Purpose:
		- Manages depot related activities
=======================================================================
"""

class BLDepotCoordinator:
	"Coordinates the management of Depot Objects"

	def __init__(self,bl_connect_manager):
		self.bl_connect_mgr = bl_connect_manager
		self.bl_connect_mgr.connect()
	
	def getBLPackageCoordinator(self):
		return BLPackageCoordinator(self.bl_connect,self)

	def groupExists(self,group_name):
		var_folder_name = group_name
		if var_folder_name.startswith('/') == 0:
			# append the '/' to the name
			var_folder_name = '/' + var_folder_name
		var_return_value = self.bl_connect_mgr.run('DepotGroup', 'groupExists', [var_folder_name])
		if var_return_value == 1:
			return 1
		return 0

	def existsDepotGroup(self,base_group_name):
		ret_value = self.bl_connect_mgr.runBoolean('DepotGroup','groupExists',base_group_name)
		return ret_value

	def normalizeGroupName(self,arg_group_name):
		if arg_group_name.startswith('/') == 0:
			arg_group_name = '/' + arg_group_name
		return arg_group_name				
	
	def createGroup(self,base_group_name):
		if self.existsDepotGroup(base_group_name) == 1:
			return
		#
		# generate the template group
		#
		group_parts = base_group_name.split('/')
		current_group = ''
		for part in group_parts:
			if part == '':
				continue
			base_group = current_group
			if base_group =='':
				base_group = '/'
			current_group = current_group + '/' + part
			if self.existsDepotGroup(current_group) == 1:
				continue
			else:
				self.createDepotGroupFromBase(base_group,part)	
		return
	
	def createDepotGroupFromBase(self,base_group_name,group_name):
		if base_group_name.startswith('/') == 0:
			# append the '/' to the name
			base_group_name = '/' + base_group_name
		var_parent_base_id = self.bl_connect_mgr.run('DepotGroup', 'groupNameToId', [base_group_name])
		var_return_value = self.bl_connect_mgr.run('DepotGroup', 'createDepotGroup', [group_name, var_parent_base_id])

	def getGroupId(self,group_name):
		group_name = self.normalizeGroupName(group_name)
		return self.bl_connect_mgr.runBladelogicCmd('DepotGroup', 'groupNameToId', [group_name])

	def getGroupName(self,group_name):
		return groupName

	def listPackagesInGroup(self,group_name):
		group_name = self.normalizeGroupName(group_name)
		return self.bl_connect_mgr.runList('DepotObject', 'listAllByGroup', [group_name])

"""
=======================================================================
	Name: BLPackageCoodinator
	Purpose:
		- Coordinates the construction of packages
		- Needs to expand to support individual package types
=======================================================================
"""

class BLPackageCoordinator:
	"Consolidates the Packaging Activities"

	def __init__(self,bl_connect_manager,depot_manager):
		self.bl_connect_mgr = bl_connect_manager
		self.bl_connect_mgr.connect()
		self.depot_manager = depot_manager


	def getPackagePropertyValue(self,param_package_name,property_name):
                var_group_index = param_package_name.rfind('/')           
		var_group_name = param_package_name[0:var_group_index]
		str_length = len( param_package_name)
		var_package_name = param_package_name[var_group_index+1:str_length]
		return self.bl_connect_mgr.run('DepotObject','getFullyResolvedPropertyValue',['BLPACKAGE',var_group_name,var_package_name,property_name])

	def setPackagePropertyValue(self,param_package_name,property_name,property_value):
                var_group_index = param_package_name.rfind('/')           
		var_group_name = param_package_name[0:var_group_index]
		str_length = len( param_package_name)
		var_package_name = param_package_name[var_group_index+1:str_length]
		package_db_key = self.getPackageDBKey(var_group_name,var_package_name)
		return self.bl_connect_mgr.run('DepotObject','setPropertyValue',[package_db_key,property_name,property_value])

	def getPackageDBKey(self,param_group_name,package_name):
		return self.bl_connect_mgr.run('BlPackage', 'getDBKeyByGroupAndName', [param_group_name, package_name])


	def addAclTemplate(self,param_package_name,param_acl_template):
                var_group_index = param_package_name.rfind('/')           
		var_group_name = param_package_name[0:var_group_index]
		str_length = len( param_package_name)
		var_package_name = param_package_name[var_group_index+1:str_length]
		package_db_key = self.getPackageDBKey(var_group_name,var_package_name)
		return self.bl_connect_mgr.run('DepotObject','applyAclTemplate',[package_db_key,param_acl_template,'false'])

	def replaceAclTemplate(self,param_package_name,param_acl_template):
                var_group_index = param_package_name.rfind('/')           
		var_group_name = param_package_name[0:var_group_index]
		str_length = len( param_package_name)
		var_package_name = param_package_name[var_group_index+1:str_length]
		package_db_key = self.getPackageDBKey(var_group_name,var_package_name)
		return self.bl_connect_mgr.run('DepotObject','applyAclTemplate',[package_db_key,param_acl_template,'true'])

	def getServerNameFromServerClass(self,arg_server_class_instance):
		#
		# extract the server name from the class name
		#
		var_server_tokens = arg_server_class_instance.split('/')
		last_entry = len(var_server_tokens)
		var_server_name = var_server_tokens[last_entry - 1]
		return var_server_name

	def getNshLocation(self,arg_server_name,arg_path):
		var_file_location = '//' + arg_server_name + arg_path
		return var_file_location

	def createNshScriptPackage(self,
				   is_central,
				   arg_depot_group_name,
				   arg_script_server,
				   arg_script_path,
				   arg_nsh_name,
				   arg_nsh_desc):
		arg_depot_group_name = self.depot_manager.normalizeGroupName(arg_depot_group_name)
		# set to the hostlist type
		if is_central == 1:
			var_script_type = 1
		else:
			var_script_type = 2
		#
		# extract the server name from the class name
		#
		var_server_name = self.getServerNameFromServerClass(arg_script_server)
		#
		#
		var_file_location = '//' + var_server_name + arg_script_path
		if var_file_location.endswith('.pl'):
			var_script_type = 3	# use perl interpreter
		return self.bl_connect_mgr.run('NSHScript',
					       'addNSHScriptToDepotByGroupName',
					       [arg_depot_group_name,
						var_script_type,
						var_file_location,
						arg_nsh_name,
						arg_nsh_desc])

	def createNshScriptPackageCentral(self,
					  arg_depot_group_name,
					  arg_script_server,
					  arg_script_path,
					  arg_nsh_name,
					  arg_nsh_desc):
		return self.createNshScriptPackage(1,
						   arg_depot_group_name,
						   arg_script_server,
						   arg_script_path,
						   arg_nsh_name,
						   arg_nsh_desc)

	def createNshScriptPackageHost(self,
				       arg_depot_group_name,
				       arg_script_server,
				       arg_script_path,
				       arg_nsh_name,
				       arg_nsh_desc):
		return self.createNshScriptPackage(0,
						   arg_depot_group_name,
						   arg_script_server,
						   arg_script_path,
						   arg_nsh_name,
						   arg_nsh_desc)

	def createNshScriptParam(self,
				 arg_depot_group_name,
				 arg_script_name,
				 arg_param_name,
				 arg_param_desc,
				 arg_param_value,
				 arg_param_setting):
		arg_depot_group_name = self.depot_manager.normalizeGroupName(arg_depot_group_name)
		return self.bl_connect_mgr.run('NSHScript',
					       'addNSHScriptParameterByGroupAndName',
					       [arg_depot_group_name,
						arg_script_name,
						arg_param_name,
						arg_param_desc,
						arg_param_value,
						arg_param_setting])

	def createSingleFilePackage(self,arg_depot_group_name, arg_server, arg_file_location, arg_name, arg_desc):
		arg_depot_group_name = self.depot_manager.normalizeGroupName(arg_depot_group_name)
		var_server_name = self.getServerNameFromServerClass(arg_server)
		var_file_location = '//' + var_server_name + arg_file_location
		return self.bl_connect_mgr.run('DepotFile',
					       'addFileToDepot',
					       [arg_depot_group_name, var_file_location, arg_name, arg_desc])

        def setBLPackageParameter(self,arg_package_name,arg_local_parameter,arg_new_value):
                var_group_index = arg_package_name.rfind('/')           
		var_group_name = arg_package_name[0:var_group_index]
		str_length = len( arg_package_name)
		var_package_name = arg_package_name[var_group_index+1:str_length]
                return self.bl_connect_mgr.run('BlPackage',
					       'setLocalParameterDefaultValue',
					       [var_package_name,var_group_name,arg_local_parameter,arg_new_value]);

	def createBLPackage(self,arg_depot_group_name,group_name, arg_desc):
		arg_depot_group_name = self.depot_manager.normalizeGroupName(arg_depot_group_name)
		var_group_id = self.depot_manager.getGroupId(arg_depot_group_name)
		return self.bl_connect_mgr.run('BlPackage',
					       'createEmptyPackage',
					       [group_name, arg_desc, var_group_id])

	def createEmptyBLPackage(self,arg_file_depot_group, arg_import_file, arg_target_depot_group, arg_package):
		arg_file_depot_group = self.depot_manager.normalizeGroupName(arg_file_depot_group)
		arg_target_depot_group = self.depot_manager.normalizeGroupName(arg_target_depot_group)
		# BlPackage importDepotObjectToPackage
		return self.bl_connect_mgr.run('BlPackage',
					       'importDepotObjectToPackage',
					       [arg_file_depot_group,
						arg_import_file,
						true,
						true,
						true,
						true,
						arg_target_depot_group,
						arg_package,
						'Action,Owner,Permission',
						'Modify,1,505',
						'NotReq',
						'NotRequired'])

	def createRPMPackage(self,arg_depot_group,arg_sw_server,arg_sw_path,arg_name,arg_desc):
		arg_bl_namespace= 'DepotSoftware'
		arg_bl_command	= 'addRpmToDepotByGroupName'
		arg_depot_group	= self.depot_manager.normalizeGroupName(arg_depot_group)
		arg_sw_server	= self.getServerNameFromServerClass(arg_sw_server)
		arg_sw_loc	= self.getNshLocation(arg_sw_server,arg_sw_path)
		return self.bl_connect_mgr.run(arg_bl_namespace,
					       arg_bl_command,
					       [arg_depot_group, arg_sw_loc, arg_name])

	def createCustomSWPackage(self,
				  arg_depot_group,
				  arg_os,arg_sw_loc,
				  arg_name,
				  arg_sw_desc,
				  arg_install_cmd,
				  arg_uninst_cmd,
				  arg_param_list,
				  arg_supp_file,
				  arg_url_type):
		arg_bl_namespace	= 'DepotSoftware'
		arg_bl_command		= 'addCustomSoftwareToDepotByGroupName'
		arg_sw_type		= 'Custom Software'
		arg_skip_param_sub 	= 'false'
		arg_skip_copy_source 	= 'false'
		arg_depot_group 	= self.depot_manager.normalizeGroupName(arg_depot_group)
		return self.bl_connect_mgr.run(arg_bl_namespace,
					       arg_bl_command,
					       [arg_depot_group,
						arg_os,
						arg_sw_type,
						arg_sw_loc,
						arg_name,
						arg_sw_desc,
						arg_install_cmd,
						arg_uninst_cmd,
						arg_param_list,
						arg_supp_file])

	def createSWInstallerPackage(self,
				     arg_depot_group,
				     arg_os,
				     arg_sw_server,
				     arg_sw_path,
				     arg_name,
				     arg_sw_desc,
				     arg_install_dir,
				     arg_use_install_dir,
				     arg_create_install_dir):
		arg_uninst_cmd	= ''
		arg_param_list	= ''
		arg_supp_file	= ''
		arg_url_type	= ''
		arg_sw_server	= self.getServerNameFromServerClass(arg_sw_server)
		arg_sw_loc	= self.getNshLocation(arg_sw_server,arg_sw_path)
		if arg_use_install_dir == 1:
			if arg_create_install_dir == 1:
				arg_install_cmd = 'mkdir -p '
				arg_install_cmd = arg_install_cmd + arg_install_dir
				arg_install_cmd = arg_install_cmd + ';cd '
				arg_install_cmd = arg_install_cmd + arg_install_dir
				arg_install_cmd = arg_install_cmd + ';'
				arg_install_cmd = arg_install_cmd + '??SOURCE??'
			else:
				arg_install_cmd = 'cd ' + arg_install_dir + ';' + '??SOURCE??'
		return self.createCustomSWPackage(arg_depot_group,
						  arg_os,
						  arg_sw_loc,
						  arg_name,
						  arg_sw_desc,
						  arg_install_cmd,
						  arg_uninst_cmd,
						  arg_param_list,
						  arg_supp_file,
						  arg_url_type)

	
	def createTARPackage(self,
			     arg_depot_group,
			     arg_os,
			     arg_sw_server,
			     arg_sw_path,
			     arg_name,
			     arg_sw_desc,
			     arg_install_dir,
			     arg_use_install_dir,
			     arg_create_install_dir):
		arg_install_cmd	= 'tar xvf ??SOURCE??'
		arg_uninst_cmd	= ''
		arg_param_list	= ''
		arg_supp_file	= ''
		arg_url_type	= ''
		arg_sw_server	= self.getServerNameFromServerClass(arg_sw_server)
		arg_sw_loc	= self.getNshLocation(arg_sw_server,arg_sw_path)
	
		if arg_use_install_dir == 1:
			if arg_create_install_dir == 1:
				arg_install_cmd = 'mkdir -p ' + arg_install_dir + ';cd ' + arg_install_dir + ';' + arg_install_cmd
			else:
				arg_install_cmd = 'cd ' + arg_install_dir + ';' + arg_install_cmd
		return self.createCustomSWPackage(arg_depot_group,
						  arg_os,
						  arg_sw_loc,
						  arg_name,
						  arg_sw_desc,
						  arg_install_cmd,
						  arg_uninst_cmd,
						  arg_param_list,
						  arg_supp_file,
						  arg_url_type)

	def createTGZPackage(self,
			     arg_depot_group,
			     arg_os,
			     arg_sw_server,
			     arg_sw_path,
			     arg_name,
			     arg_sw_desc,
			     arg_install_dir,
			     arg_use_install_dir,
			     arg_create_install_dir):
		arg_install_cmd	= 'tar xvf ??SOURCE??'
		arg_uninst_cmd	= ''
		arg_param_list	= ''
		arg_supp_file	= ''
		arg_url_type	= ''
		arg_sw_server	= self.getServerNameFromServerClass(arg_sw_server)
		arg_sw_loc	= self.getNshLocation(arg_sw_server,arg_sw_path)
	
		if arg_use_install_dir == 1:
			if arg_create_install_dir == 1:
				arg_install_cmd = 'mkdir -p ' + arg_install_dir + ';cd ' + arg_install_dir + ';' + arg_install_cmd
			else:
				arg_install_cmd = 'cd ' + arg_install_dir + ';' + arg_install_cmd
		return self.createCustomSWPackage(arg_depot_group,
						  arg_os,
						  arg_sw_loc,
						  arg_name,
						  arg_sw_desc,
						  arg_install_cmd,
						  arg_uninst_cmd,
						  arg_param_list,
						  arg_supp_file,
						  arg_url_type)

	def createZIPPackage(self,
			     arg_depot_group,
			     arg_os,
			     arg_sw_server,
			     arg_sw_path,
			     arg_name,
			     arg_sw_desc,
			     arg_install_dir,
			     arg_use_install_dir,
			     arg_create_install_dir):
		arg_install_cmd	= 'cp ??SOURCE?? .'
		arg_uninst_cmd	= ''
		arg_param_list	= ''
		arg_supp_file	= ''
		arg_url_type	= ''
		arg_sw_server	= self.getServerNameFromServerClass(arg_sw_server)
		arg_sw_loc	= self.getNshLocation(arg_sw_server,arg_sw_path)
	
		if arg_use_install_dir == 1:
			if arg_create_install_dir == 1:
				arg_install_cmd = 'mkdir -p ' + arg_install_dir + ';cd ' + arg_install_dir + ';' + arg_install_cmd
			else:
				arg_install_cmd = 'cd ' + arg_install_dir + ';' + arg_install_cmd
			
		return self.createCustomSWPackage(arg_depot_group,
						  arg_os,
						  arg_sw_loc,
						  arg_name,
						  arg_sw_desc,
						  arg_install_cmd,
						  arg_uninst_cmd,
						  arg_param_list,
						  arg_supp_file,
						  arg_url_type)


	def mapPrimitiveType(self,param_type):
		if param_type.find('Primitive') == 0:
			return param_type
		if param_type.find('Class') == 0:
			return param_type
		if param_type.find('List') == 0:
			return param_type
		if param_type.find('Enum') == 0:
			return param_type
		#
		# remap to 3 different 
		#
		if param_type == '':
			return 'Primitive:/String'
		if param_type.lower() == 'string':
			return 'Primitive:/String'
		if param_type.lower() == 'integer':
			return 'Primitive:/Integer'
		if param_type.lower() == 'date':
			return 'Primitive:/Date'
		if param_type.lower() == 'boolean':
			return 'Primitive:/Boolean'
		if param_type.lower() == 'decimal':
			return 'Primitive:/Decimal'

		return 'Class:/SystemObject' + param_type

	def addSimpleLocalPropClassParameter(self,
					     param_package_name,
					     param_prop_name,
					     param_prop_class):
		return self.addSimpleParameter(param_package_name,
					       param_prop_name,
					       param_prop_class)

	def addSimpleBooleanParameter(self,param_package_name,param_prop_name):
		return self.addSimpleParameter(param_package_name,
					       param_prop_name,
					       'Primitive:/Boolean')
	

	def addSimpleIntegerParameter(self,param_package_name,param_prop_name):
		return self.addSimpleParameter(param_package_name,
					       param_prop_name,
					       'Primitive:/Integer')

	def addSimpleStringParameter(self,param_package_name,param_prop_name):
		return self.addSimpleParameter(param_package_name,
					       param_prop_name,
					       'Primitive:/String')

	def addSimpleParameter(self,param_package_name,param_prop_name,param_type):
                var_group_index = param_package_name.rfind('/')           
		var_group_name = param_package_name[0:var_group_index]
		str_length = len( param_package_name)
		var_package_name = param_package_name[var_group_index+1:str_length]
		var_property = param_prop_name
		var_type = self.mapPrimitiveType(param_type)
		var_editable = 'true'
		var_required = 'false'
		var_default_val = ''
		return self.addLocalParameter(var_package_name,
					      var_group_name,
					      var_property,
					      var_property,
					      var_type,
					      var_editable,
					      var_required,
					      var_default_val)
	

	def addLocalParameter(self,
			      param_package_name,
			      param_group_name,
			      param_prop_name,
			      param_prop_desc,
			      param_prop_type,
			      param_editable,
			      param_required,
			      param_default_val):
		var_package_name = param_package_name
		var_group_name = param_group_name
		var_prop_name = param_prop_name
		var_prop_desc = param_prop_desc
		var_prop_type = self.mapPrimitiveType(param_prop_type)
		var_editable = param_editable
		var_required = param_required
		var_default_val = param_default_val

		if 0:
			print "VAR_PACKAGE_NAME: " + var_package_name
			print "VAR_GROUP_NAME: " + var_group_name
			print "VAR_PROP_NAME: " + var_prop_name
			print "VAR_PROP_DESC: " + var_prop_desc
			print "VAR_PROP_TYPE: " + var_prop_type
			print "VAR_EDITABLE: " + var_editable
			print "VAR_REQUIRED: " + var_required

		return self.bl_connect_mgr.runIgnore('BlPackage',
						    'addLocalParameter',
						     [var_package_name,
						      var_group_name,
						      var_prop_name,
						      var_prop_desc,
						      var_prop_type,
						      var_editable,
						      var_required,
						      var_default_val])	

"""
=======================================================================
	Name: BLJobCoordinator
	Purpose:
		- Manages job activities
		- An integrated DepotJobManager will use it to coordiante depot and job activities
=======================================================================
"""

class BLJobCoordinator:
	"Coordinates the management of Jobs"	

	def __init__(self,bl_connect_manager):
		self.bl_connect_mgr = bl_connect_manager
		self.bl_connect_mgr.connect()


	def groupExists(self,group_name):
		var_folder_name = group_name
		if var_folder_name.startswith('/') == 0: var_folder_name = '/' + var_folder_name
		var_return_value = self.bl_connect_mgr.runBladelogicCmd('JobGroup', 'groupExists', [var_folder_name])
		#print "Exists? " + var_folder_name + " result: " + str(var_return_value)
		if var_return_value == 1:
			return 1
		return 0

	def createJobGroup(self,param_folder_name):
		if self.groupExists(param_folder_name) == 1:
			return
		#
		# generate the template group
		#
		group_parts = param_folder_name.split('/')
		current_group = ''
		for part in group_parts:
			if part == '':
				continue
			base_group = current_group
			if base_group =='':
				base_group = '/'
			current_group = current_group + '/' + part
			if self.groupExists(current_group) == 1:
				print "Exists: " + base_group + "/" + part
				continue
			else:
			  self.createGroup(base_group, part)	
		return
	

	def normalizeGroupName(self,arg_group_name):
		if arg_group_name.startswith('/') == 0:
			arg_group_name = '/' + arg_group_name
		return arg_group_name

	def createGroup(self,base_group_name, group_name):
		if base_group_name.startswith('/') == 0:
			base_group_name = '/' + base_group_name # prepend the '/' 
		var_parent_base_id = self.bl_connect_mgr.run('JobGroup', 'groupNameToId', [base_group_name])
		#print("Creating Group: " + base_group_name + "/" + group_name)
		var_result = self.bl_connect_mgr.runBladelogicCmd('JobGroup',
								  'createJobGroup',
								  [group_name, var_parent_base_id])

	def getGroupId(self,arg_job_group_name):
		return self.bl_connect_mgr.run('JobGroup', 'groupNameToId', [arg_job_group_name])

	def createDeployJob(self, package_group, package_name, job_group, job_name, server_name):
		package_id = self.bl_connect_mgr.run('BlPackage',
											'getDBKeyByGroupAndName',
											[package_group,
											package_name])
		# BJB - Had to chop trailing slash from group
		if(job_group.endswith('/')): job_group = job_group[:-1]
		self.createJobGroup(job_group)
		job_group_id = self.bl_connect_mgr.run('JobGroup',
												'groupNameToId',
												job_group)
		isSimulateEnabled="true"
		isCommitEnabled="true"
		isStagedIndirect="false"
		deploy_job_key = self.bl_connect_mgr.run('DeployJob',
												'createDeployJob',
												[ job_name,
												job_group_id,
												package_id,
												server_name,
												isSimulateEnabled,
												isCommitEnabled,
												isStagedIndirect])
		return deploy_job_key				

	def createSWDeployJob(self,arg_model_type, arg_job_group, arg_db_key, arg_job_name, arg_server_group):
		arg_bl_namespace = 'DeployJob'
		arg_bl_command	 = 'createSoftwareDeployJob'
		arg_job_group	 = self.depot_manager.normalizeGroupName(arg_job_group)
		arg_job_group_id = bl_get_job_group_id(arg_job_group)
		arg_simulate	 = 'true'
		arg_commit	 = 'true'
		arg_staged	 = 'true'
		#
		# server groups are not allowed within the server name so instead, we will need to add a fake
		# server and remove it from the list and then add the server group.
		#
		arg_temp_server	= self.bl_connect_mgr.getAppServer()
		arg_job_key = self.bl_connect_mgr.run(arg_bl_namespace,
						      arg_bl_command,
						      [arg_job_name,
						       arg_job_group_id,
						       arg_db_key,
						       arg_model_type,
						       arg_temp_server,
						       arg_simulate,
						       arg_commit,
						       arg_staged])
		#
		# removes the servers
		#
		arg_bl_namespace		= 'Job'
		arg_bl_command			= 'clearTargetServers'
		arg_job_key = self.bl_connect_mgr.run(arg_bl_namespace, arg_bl_command, [arg_job_key])
		#
		# add the server group to the job
		#
		arg_bl_namespace		= 'Job'
		arg_bl_command			= 'addTargetGroup'
		return self.bl_connect_mgr.run(arg_bl_namespace,
					       arg_bl_command,
					       [arg_job_key, arg_server_group])

	def createRPMDeployJob(self,arg_job_group,arg_db_key,arg_job_name,arg_server_group):
		return self.createSWDeployJob('RPM_INSTALLABLE',
					      arg_job_group,
					      arg_db_key,
					      arg_job_name,
					      arg_server_group)

	def createCustomDeployJob(self,arg_job_group,arg_db_key,arg_job_name,arg_server_group):
		return self.createSWDeployJob('CUSTOM_SOFTWARE_INSTALLABLE',
					      arg_job_group,
					      arg_db_key,
					      arg_job_name,
					      arg_server_group)

	def createNSHScriptsJob(self,arg_job_group,arg_script_group, arg_script_name,arg_job_name,arg_server_group, arg_description):
		arg_bl_namespace 	= 'NSHScriptJob'
		arg_bl_command		= 'createNSHScriptJob'
		arg_parallel_exec	= 1
		arg_job_group		= self.depot_manager.normalizeGroupName(arg_job_group)
		arg_script_group 	= self.depot_manager.normalizeGroupName(arg_script_group)
		arg_temp_server		= self.bl_connect_mgr.getAppServer()
		save_job_key = self.bl_connect_mgr.run(arg_bl_namespace,
						       arg_bl_command,
						       [arg_job_group,
							arg_job_name,
							arg_description,
							arg_script_group,
							arg_script_name,
							arg_temp_server,
							arg_parallel_exec ])
		#
		# removes the servers
		#
		arg_bl_namespace		= 'Job'
		arg_bl_command			= 'clearTargetServers'
		arg_job_key = self.bl_connect_mgr.run(arg_bl_namespace, arg_bl_command, [arg_job_key])
		#
		# add the server group to the job
		#
		arg_bl_namespace		= 'Job'
		arg_bl_command			= 'addTargetGroup'
		return self.bl_connect_mgr.run(arg_bl_namespace, arg_bl_command, [arg_job_key, arg_server_group])

	def createBatchJob(self,arg_job_group,arg_batch_job_key_list,arg_job_name,arg_server_group):
		if len(arg_batch_job_key_list) == 0:
			self.common.printError('bl_create_batch_job: no job keys were specified')
			return ''
		arg_job_group			= self.depot_manager.normalizeGroupName(arg_job_group)
		arg_job_group_id		= bl_get_job_group_id(arg_job_group)
		var_first_entry = 1
		var_first_job_key	= ''
		for job_key in arg_batch_job_key_list:
			if var_first_entry == 1:
				var_first_entry = 0
				#
				# create the batch job
				#
				arg_bl_namespace		= 'BatchJob'
				arg_bl_command			= 'createBatchJob'
				arg_continue_on_error 	= 'false'
				arg_execute_by_stage 	= 'false'	# executes by server
				arg_override_targets	= 'true'	# override targets with the job
				var_first_job_key = self.bl_connect_mgr.run(arg_bl_namespace,
									    arg_bl_command,
									    [arg_job_name,
									     arg_job_group_id,
									     job_key,
									     arg_continue_on_error,
									     arg_execute_by_stage,
									     arg_override_targets ])
			else:
				#
				# attach the additional jobs to the batch
				#
				arg_bl_namespace	= 'BatchJob'
				arg_bl_command		= 'addMemberJobByJobKey'
				var_batch_member_key = self.bl_connect_mgr.run(arg_bl_namespace,
									       arg_bl_command,
									       [var_batch_job_key, job_key])
		#
		# attach the server group to the current batch job
		#
		arg_bl_namespace		= 'Job'
		arg_bl_command			= 'addTargetGroup'
		var_result = self.bl_connect_mgr.runBladelogicCmd(arg_bl_namespace,
								  arg_bl_command,
								  [var_batch_job_key, arg_server_group])
		return var_first_job_key
	
	def executeJob(self,arg_job_key):
		return self.bl_connect_mgr.run('Job', 'execute', [arg_job_key])

	def executeComponentJob(self, grp_path):
		grp_path = self.group_component_path
		grp_path = grp_path + "/" + component_template
		jobCoordinator = blm.BLJobCoordinator(self.bl_connect_mgr)
		job_key = blm.BLJobCoordinator.getJobKey(self, grp_path, job_name)
		return jobCoordinator.executeJobAndWait(job_key)

	def executeJobAndWait(self,arg_job_key, approval_id = "none"):
		if(approval_id == "none"):
			return self.bl_connect_mgr.run('DeployJob', 'executeJobAndWait', [arg_job_key])
		else:
			return self.bl_connect_mgr.run('DeployJob', 'executeJobAndWaitWithApproval', [arg_job_key, approval_id])

	def getGroupName(self,group_name):
		return groupName
		
	def getJobKey(self, arg_group, arg_job, arg_type = 'DeployJob'):
		return self.bl_connect_mgr.run(arg_type, 'getDBKeyByGroupAndName', [arg_group, arg_job])

	def getApproval(self, comment = "BRPM Deploy"):
		arg_approvalType = 0 # No Approval
		arg_changeType = 2 # Change
		arg_comments = comment
		arg_impactID = 0
		arg_riskLevel = 0
		arg_changeID = 0 # Not required with approvalType 0
		arg_taskID = 0 # Not required with approvalType 0
		return self.bl_connect_mgr.run('Job', 'getApproval', [arg_approvalType, arg_changeType, arg_comments, arg_impactID, arg_riskLevel])

	def addServersToJob(self,arg_job_key, arg_servers):
		result = self.bl_connect_mgr.run('Job', 'addTargetServers', [arg_job_key, arg_servers])
		return result

	def removeServersFromJob(self,arg_job_key):
		result = self.bl_connect_mgr.run('Job', 'clearTargetServers', [arg_job_key])
		return result

	def addComponentTargetToJob(self,arg_job_key, arg_component_key):
		result = self.bl_connect_mgr.run('Job', 'addTargetComponent', [arg_job_key, arg_component_key])
		return result

	def setBLJobParameter(self,arg_job_name,arg_prop_name,arg_prop_value):
		return self.updateJobPropertyValue(arg_job_name,arg_prop_name,arg_prop_value)

	def updateJobPropertyValue(self,arg_job_path,arg_prop_name,arg_prop_value):
                var_group_index = arg_job_path.rfind('/')           
		var_job_group = arg_job_path[0:var_group_index]
		str_length = len( arg_job_path)
		var_job_name = arg_job_path[var_group_index+1:str_length]
		var_result = self.bl_connect_mgr.run('DeployJob',
						     'setOverriddenParameterValue',
						     [var_job_group,var_job_name,arg_prop_name,arg_prop_value])

	def listJobsInGroup(self,group_name):
		group_name = self.normalizeGroupName(group_name)
		return self.bl_connect_mgr.runList('Job', 'listAllByGroup', [group_name])

"""
=======================================================================
	Name: BLPackageJobCoordinator
	Purpose:
		- Coordinates activities for package and job creation
		- Eliminates "excess parameters" based on standard settings
		- Uses a parameterized configuration to identify build strategies
=======================================================================
"""

class BLPackageJobCoordinator:
	"Coordinates Package and Job Creation Via Standardization"

	def __init__(self,bl_connect_manager,bl_depot_manager,bl_job_manager,group_name):
		self.bl_connect_mgr	= bl_connect_manager
		self.bl_connect_mgr.connect()
		self.bl_depot_manager 	= bl_depot_manager
		self.bl_job_manager	= bl_job_manager
		self.group_name		= group_name

	#
	# NSH Script Package, Job, and Create
	#
	def getNshPackage(self,script_server,script_path,nsh_name,nsh_description):
		return BLNshPackage(self.bl_depot_manager,
				    self.bl_job_manager,
				    self.group_name,
				    script_server,
				    script_path,
				    nsh_name,
				    nsh_description)

	def createNshPackage(self,bl_nsh_package):
		bl_nsh_package.createPackage()

	def createNshJob(self,bl_nsh_package,job_name,server_group):
		bl_nsh_package.createJob(job_name,server_group)

	def deployNshPackage(self,script_server,script_path,nsh_name,description,job_name,server_group):
		bl_nsh_package = self.getNshPackage(script_server,script_path,nsh_name,description)
		bl_nsh_package.createPackage()
		bl_nsh_package.createJob(job_name,server_group)


"""
=======================================================================
	Name: BLNshPackage
	Purpose:
		- coordinate activities for NSH building
=======================================================================
"""

class BLNshPackage:
	"Consolidates the NSH Package as a standard build package"

	def __init__(self,bl_depot_manager,bl_job_manager,group_name,script_server,script_path,nsh_name,description):
		self.bl_depot_manager	= bl_depot_manager
		self.bl_job_manager	= bl_job_manager
		self.central		= 1
		self.group_name		= group_name
		self.script_server	= script_server
		self.script_path	= script_path
		self.nsh_name		= nsh_name
		self.description	= description
		self.db_key		= ''
		self.job_key		= ''

	def getCentral(self):
		return self.central

	def getGroupName(self):
		return self.group_name

	def getJobGroup(self):
		return self.bl_job_manager.getGroupName(group_name)

	def getDepotGroup(self):
		return self.bl_depot_manager.getGroupName(group_name)

	def getScriptServer(self):
		return self.script_server

	def getScriptPath(self):
		return self.script_path

	def getNshName(self):
		return self.nsh_name

	def getDescription(self):
		return self.description

	def getDbKey(self):
		return self.db_key

	def getJobKey(self):
		return self.job_key
		
	def createPackage(self):
		self.db_key = self.bl_depot_manager.createNshScriptPackage(self.central,
			self.getDepotGroup(),
			self.script_server,
			self.script_path,
			self.nsh_name,
			self.description)

	def createJob(self,job_name,server_group):
		self.job_key = self.bl_job_manager.createNSHScriptsJob(self.getJobGroup(),
				self.getJobGroup(),
				job_name,
				server_group,
				self.description)
