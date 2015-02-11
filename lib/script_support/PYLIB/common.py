#!/usr/bin/jython
# coding=UTF-8
#
# Module Name: foundation.jy
#
# Purpose:
#	store foundational library functions
#
# Version:
#

"""
	====================================================================
	IMPORT STATEMENTS
	====================================================================
"""

import sys
import re
import os
import tempfile
import time
import os
from java.lang import Class

class CommonUtility:
	"Contains basic common utilities"

	def __init__(self):
		self.description = "contains utilities"

	def strToBoolean(self, param_bool_str):
		if param_bool_str.lower() == 'false':
			return 0
		return 1

class CommonManager:
	"Coordinates activities with the running system"

	def __init__(self):
		self.description 	= "simple mechanism to manage foundational elements"
		self.execution_status = 1
		self.trace_status	= 0
		self.trace_string	= ''
		self.debug_status	= 0
		#
		# 0 - Inactive
		# 1 - Low (Default)
		# 2 - Medium
		# 3 - High
		# 
		self.debug_setting 	= 1

	def parseLineIntoWords(self,arg_line):
		words = [ ]
		#
		# Remove whitespaces in between lines
		#
		arg_line = arg_line.strip()
		words_list = arg_line.split()
		for word in words_list:
			word = word.strip()
			if word != '':
				words.append(word)
		return words

	def getExecutionStatus(self):
		return self.execution_status

	def activateDebugging(self):
		self.debug_status = 1
		self.debug_setting = 1

	def deactivateDebugging(self):
		self.debug_status = 0
		self.debug_setting = 0

	def activateLowDebug(self):
		self.activateDebugging()
		self.debug_setting = 1

	def activateMediumDebug(self):
		self.activateDebugging()
		self.debug_setting = 2
	
	def activateHighDebug(self):
		self.activateDebugging()
		self.debug_setting = 3

	def debugLow(self,arg_text):
		if self.debug_status == 1:
			self.printTrace('D', arg_text)
			if self.debug_setting >= 1:
				sys.stdout.write(" -- DEBUG_LOW: " + str(arg_text) + '\n')

	def debugMedium(self,arg_text):
		if self.debug_status == 1:
			self.printTrace('D', arg_text)
			if self.debug_setting >= 2:
				sys.stdout.write(" -- DEBUG_MED: " + str(arg_text) + '\n')

	def debugHigh(self,arg_text):
		if self.debug_status == 1:
			self.printTrace('D', arg_text)
			if self.debug_setting >= 3:
				sys.stdout.write(" -- DEBUG_HIGH: " + str(arg_text) + '\n')

	def registerTrace(self,traceOption):
		self.trace_string = self.trace_string + traceOption

	def printTrace(self,arg_trace_string,arg_print_string):
		global glob_trace_string
		trace_on	= 0
		trace_len	= len(arg_trace_string)
		i = 0
		while (i < trace_len):
			setvalue = arg_trace_string[i]
			# sys.stdout.write('trace_string: ' + glob_trace_string + '\n')
			# sys.stdout.write('setvalue    : ' + setvalue + '\n')
			if glob_trace_string.find(setvalue) != -1:
				trace_on = 1
				break
			i = i + 1
		if trace_on == 1:
			sys.stdout.write(' -- TRACE[' + arg_trace_string + '] ' + str(arg_print_string) + '\n')

	def executeCommand(self,arg_command):
		self.executeCommandInternal(self,0,arg_command)

	def executeCommandIgnore(self,arg_command):
		self.executeCommandInternal(self,True,arg_command)

	def executeCommandInternal(self,ignore_failure,arg_command):
		text_lines = [ ]
		self.execution_status = True
		self.debugHigh('Executing Command: ' + arg_command)

		stdout_handle = os.popen(arg_command, "r")
		text = stdout_handle.read()
		text_lines = text.splitlines()
		status = stdout_handle.close()
	
		if self.debug_setting == 'High':
			for line in text_lines:
				self.debugHigh(line)
		if status != None:
			self.execution_status = 0

		if status != None:
			glob_execution_passed = 0
			if ignore_failure == 0:
				self.bl_connect.getFoundation().printError('Execution of Command Failed: ' + arg_command)
				for line in text_lines:
					self.bl_connect.getFoundation().printError(line)
				sys.exit(1)

		for line in text_lines:
			self.trace(line);
		return text_lines

	def pr(self,arg_text):
		self.printInfo(arg_text)
		
	def printInfo(self,arg_text):
		sys.stdout.write(" -- INFO: " + str(arg_text) + '\n')

	def error(self,arg_text):
		self.printError(arg_text)
		
	def printError(self,arg_error):
		sys.stderr.write(" -- ERROR: " + str(arg_error) + '\n')
	
	def fileExists(self,file_name):
		if os.path.exists(file_name):
			return 1
		return 0

	def getFilesNoExtension(self,directory_name,extension):
		name_list = [ ]
		if os.path.isdir(directory_name):
			files = os.listdir(directory_name)
			for x in files:
				if (x.endswith(extension)):
					new_name = x[0:len(x)-len(extension)]
					name_list.append(new_name)
		return name_list
					
		
	def removeFilesFromDir(self,directory_name):
		#
		# remove files from a directory
		#
		if os.path.isdir(directory_name):
			files = os.listdir(directory_name)
			for x in files:
				fullpath =os.path.join(path, x)
				if os.path.isfile(fullpath):
					os.remove(fullpath)

	def removeOlderFilesFromDir(self,directory_name, days_limit):
		#
		# remove files from a directory ...
		#
		if not os.path.isdir(directory_name):
			return
		files=os.listdir(directory_name)
		
		for x in files:
			fullpath=os.path.join(directory_name, x)
			if os.path.isfile(fullpath):
				statinfo = os.stat(fullpath)
				st_mtime = statinfo.st_mtime
				ts_ctime = time.ctime()
				diffsec = ts_ctime - st_mtime
				age_limit = 60 * 60 * 24 * days_limit
				if diffsec > age_limit:
					os.remove(fullpath)
		

	def writePropValueFile(self,file_name,instance_property_dict):
		#
		# Writing Property Value File
		#
		if len(instance_property_dict.keys()) == 0:
			return
		self.printInfo('Writing file: ' + str(file_name))
		FILE = open(file_name,'w')
		for property_name in instance_property_dict.keys():
			FILE.write(property_name)
			FILE.write('=')
			FILE.write(instance_property_dict[property_name])
			FILE.write('\n')
		FILE.close()
	
	def readPropValueFile(self,file_name):
		#
		# Reading Property Value File
		#
		instance_property_dict = { }
		self.printInfo('Reading in file: ' + str(file_name))
		if os.path.exists(file_name):
			FILE = open(file_name,'r')
			#
			# read the first line which should be the key
			#
			key_list = [ ]
			if FILE:
				while 1:
					line = FILE.readline()
					if not line:
						break
					line = line.rstrip('\n')
					prop_value_list = line.split('=')
					prop_key	= prop_value_list[0]
					prop_value	= prop_value_list[1]
					instance_property_dict[prop_key] = prop_value
		return instance_property_dict				

	def writeFile(self,file_name,output_data):
		self.printInfo('Writing file: ' + str(file_name))
		output_str = str(output_data)
		FILE = open(file_name,'w')
		FILE.write(output_str)
		FILE.close()
		
	def writeListFile(self,file_name,output_list):
		self.printInfo('Writing list file: ' + str(file_name))
		FILE = open(file_name,'w')
		for output_str in output_list:
			FILE.write(output_str)
			FILE.write('\n')
		FILE.close()

	def writeDumpFile(self,file_name,instance_property_dict):
		if len(instance_property_dict.keys()) == 0:
			return
		self.printInfo('Writing file: ' + str(file_name))
		FILE = open(file_name,'w')

		column_names	= []
		FILE.write('instance_name')
		for instance_name in instance_property_dict.keys():
			property_dict = instance_property_dict[instance_name]
			for property_name in property_dict.keys():
				column_names.append(property_name)
				FILE.write(',')
				FILE.write(property_name)
			break
		FILE.write('\n')
		FILE.close()
		
	def readPropertyFile(self,file_name):
		instance_property_dict = { }
		self.printInfo('Reading in file: ' + str(file_name))
		if os.path.exists(file_name):
			FILE = open(file_name,'r')
			#
			# read the first line which should be the key
			#
			key_list = [ ]
			if FILE:
				line = FILE.readline()
				line = line.rstrip('\n')
				key_list = line.split(',')
				if key_list[0] == 'instance_name':
					#
					# read each line
					#
					records_processed = 0
					instance_name = ''
					last_instance_name = ''
					error_detected = 0
					while 1:
						line = FILE.readline()
						# print "line: " + line
						if not line:
							break
						if error_detected == 1:
							print "line: " + line
							error_detected = 0
						line = line.rstrip('\n')
						value_list = line.split(',')
						instance_props = { }
						count = 0
						if len(key_list) == len(value_list):
							records_processed = records_processed + 1
							while count < len(key_list):
								key_data = key_list[count]
								value_data = value_list[count]
								value_data = value_data.lstrip('"')
								value_data = value_data.rstrip('"')
								count = count + 1
								if key_data == 'instance_name':
									instance_name = value_data
									last_instance_name = instance_name
								else:
									# print "assigning " + key_data + " value: " + value_data								
									instance_props[key_data] = value_data
							# sys.exit(-1)
							instance_property_dict[instance_name] = instance_props
						else:
							self.printInfo('Key list mismatch error detected in the dump reading, records processed: ' + str(records_processed) + ' last instance: ' + last_instance_name)
							error_detected = 1
			FILE.close()
		return instance_property_dict

	def createPropertyFile(self,file_name,column_property_dict):
		self.writeDumpFile(file_name,column_property_dict)

	def appendDumpFile(self,file_name,instance_name,instance_property_dict):
		self.printInfo('Appending file : ' + str(file_name))
		self.printInfo('Instance name  : ' + instance_name)
		FILE = open(file_name,'a')
		
		for instance_name in instance_property_dict.keys():
			if instance_name != '':
				FILE.write('"')
				FILE.write(instance_name)
				FILE.write('"')
				property_dict = instance_property_dict[instance_name]
				for property_name in property_dict.keys():
					property_value = property_dict[property_name]
					FILE.write(',')
					FILE.write('"')
					FILE.write(property_value)
					FILE.write('"')
				FILE.write('\n')
		FILE.close()


	def dumpFile(self,file_name,instance_property_dict):
		self.printInfo('Writing file: ' + str(file_name))
		FILE = open(file_name,'w')

		column_names	= []
		FILE.write('instance_name')
		for instance_name in instance_property_dict.keys():
			property_dict = instance_property_dict[instance_name]
			for property_name in property_dict.keys():
				column_names.append(property_name)
				FILE.write(',')
				FILE.write(property_name)
			break
		FILE.write('\n')

		for instance_name in instance_property_dict.keys():
			if instance_name != '':
				FILE.write('"')
				FILE.write(instance_name)
				FILE.write('"')
				property_dict = instance_property_dict[instance_name]
				for property_name in column_names:
					if property_name in property_dict:
						property_value = property_dict[property_name]
						# self.printInfo('Property: ' + property_name + ' Value: ' + str(property_value))
						FILE.write(',')
						FILE.write('"')
						FILE.write(property_value)
						FILE.write('"')
					else:
						FILE.write(',')
						FILE.write('"')
						FILE.write('EMPTY')
						FILE.write('"')				
				FILE.write('\n')
		FILE.close()

	def readCSVFile(self,param_key_name,file_name):
		instance_property_dict = { }
		self.printInfo('Reading in file: ' + str(file_name))
		if os.path.exists(file_name):
			FILE = open(file_name,'r')
			#
			# read the first line which should be the key
			#
			key_list = [ ]
			if FILE:
				line = FILE.readline()
				line = line.rstrip('\n')
				key_list = line.split(',')
				key_exists = 0
				key_index  = 0
				for item in key_list:
					if item == param_key_name:
						key_exists = 1
						break
					key_index = key_index + 1

				if key_exists == 1:
					#
					# read each line
					#
					records_processed = 0
					instance_name = ''
					last_instance_name = ''
					error_detected = 0
					while 1:
						line = FILE.readline()
						if not line:
							break
						if error_detected == 1:
							print "line: " + line
							error_detected = 0
						line = line.rstrip('\n')
						value_list = line.split('","')
						instance_props = { }
						count = 0
						if len(key_list) == len(value_list):
							records_processed = records_processed + 1
							while count < len(key_list):
								key_data = key_list[count]
								value_data = value_list[count]
								value_data = value_data.lstrip('"')
								value_data = value_data.rstrip('"')
								count = count + 1
								if key_data == param_key_name:
									instance_name = value_data
									last_instance_name = instance_name
								else:
									instance_props[key_data] = value_data
							# sys.exit(-1)
							instance_property_dict[instance_name] = instance_props
						else:
							self.printInfo('Key list mismatch error detected in the dump reading, records processed: ' + str(records_processed) + ' last instance: ' + last_instance_name)
							error_detected = 1
			FILE.close()
		return instance_property_dict

	def readDumpFile(self,file_name):
		return self.readCSVFile('instance_name',file_name)

	def readDataPropertiesDirectory(self,key_name,file_ext,data_directory):
		if not os.path.isdir(data_directory):
			return
		files=os.listdir(data_directory)
		
		count = 0
		instance_property_dict = { }
		for x in files:
			if x.endswith(file_ext):
				count = count + 1
				property_dict = { }
				fullpath=os.path.join(data_directory, x)		
				# print 'reading in file: ' + fullpath	
				FILE = open(fullpath,'r')
				instance_name = ''
				while 1:
					line = FILE.readline()
					line = line.rstrip('\n')
					if not line:
						break
					prop_value_entry_list = line.split('=')
					prop_value_entry_key = prop_value_entry_list[0]
					prop_value_entry_val = prop_value_entry_list[1]
					if prop_value_entry_key == key_name:
						instance_name = prop_value_entry_val
					property_dict[prop_value_entry_key] = prop_value_entry_val
					# print 'key: ' + prop_value_entry_key + ' value: ' + prop_value_entry_val
				#
				# assign the property dictionary to the instance_name
				#
				if instance_name <> '':
					instance_property_dict[instance_name] = property_dict
				FILE.close()
		# print 'reading file completed'
		return instance_property_dict

	def readDataListDirectory(self,key_name,key_value,file_ext,data_directory):
		#
		# NAME = FILE_NAME
		# KEY_NAME = PROPERTY_NAME
		# KEY_VALUE = PROPERTY_VALUE
		#
		if not os.path.isdir(data_directory):
			return
		files=os.listdir(data_directory)
		
		count = 0
		instance_property_dict = { }
		for x in files:
			if x.endswith(file_ext):
				count = count + 1
				
				fullpath=os.path.join(data_directory, x)		
				# print 'reading in file: ' + fullpath	
				FILE = open(fullpath,'r')
				while 1:
					line = FILE.readline()
					line = line.rstrip('\n')
					if not line:
						break
					prop_value_entry_list = line.split('=')
					prop_value_entry_key = prop_value_entry_list[0]
					prop_value_entry_val = prop_value_entry_list[1]
					property_dict = { }
					property_dict[key_name] = x.rstrip(file_ext)
					property_dict[key_value] = prop_value_entry_val
					instance_property_dict[prop_value_entry_key] = property_dict
					# print 'key: ' + prop_value_entry_key + ' value: ' + prop_value_entry_val
				FILE.close()
		# print 'reading file completed'
		return instance_property_dict

	def readDataContentDirectory(self,file_ext,data_directory):
		#
		# FORMAT:
		#	DIR => FILE_NAME.<ext> with BASIC CONTENT
		#
		if not os.path.isdir(data_directory):
			return
		files=os.listdir(data_directory)
		
		count = 0
		instance_property_dict = { }
		for x in files:
			fname = x.upper()
			if fname.endswith(file_ext.upper()):
				count = count + 1
				
				fullpath=os.path.join(data_directory, x)
				FILE = open(fullpath,'r')
				property_list = [ ]
				while 1:
					line = FILE.readline()
					line = line.rstrip('\n')
					if not line:
						break
					property_list.append(line)
				#
				# With the list, create an entry for the name
				#
				file_name = x.rstrip(file_ext.upper())
				file_name = file_name.rstrip(file_ext.lower())
				file_name = file_name.rstrip('.')
				# print "x: " + x + " f: " + file_name + " e: " + file_ext
				instance_property_dict[file_name] = property_list
				FILE.close()
		return instance_property_dict

class CommonArgParser:
	"Process the command-line arguments for a program"

	def __init__(self,script_name):
		self.foundation = CommonManager()
		self.sysargs = sys.argv
		self.script_name = script_name
		self.options_dict = { }
		self.required_dict = { }	
		self.argument_dict = { }
		self.is_validated = 0

	def setOptionalArgs(self,str_option):
		self.options_dict[str_option] = 'true'
	
	def setOptionalNoArgs(self,str_option):
		self.options_dict[str_option] = 'false'

	def setRequiredArgs(self,str_option):
		self.options_dict[str_option] = 'true'
		self.required_dict[str_option] = 'false'
	
	def setRequiredNoArgs(self,str_option):
		self.options_dict[str_option] = 'false'
		self.required_dict[str_option] = 'false'
		
	def isSet(self,str_option):
		#
		# if argument is in the argument list, then set
		#
		if self.is_validated == 0:
			self.validateRequired()
		if str_option in self.argument_dict.keys():
			return 1
		return 0
	
	def getValue(self,str_option):
		if self.is_validated == 0:
			self.validateRequired()	
		if str_option in self.argument_dict.keys():
			return self.argument_dict[str_option]
		self.foundation.printError('Failed to get value for argument: ' + str_option + " for " + self.script_name)
		sys.exit(-1)

	def validateRequired(self):
		#	
		# parses the command line and stores the data in arguments dict.
		#
		self.is_validated = 1
		is_value = 0
		last_parameter = ''
		for parameter in self.sysargs:
			if is_value == 0:
				#
				# check parameter value
				#
				if parameter in self.options_dict.keys():
					req_parameter = self.options_dict[parameter]
					if req_parameter == 'true':
						last_parameter = parameter
						self.required_dict[parameter] = 'true'
						is_value = 1
					else:
						self.argument_dict[parameter] = ''
						self.required_dict[parameter] = 'true'
						last_parameter = ''
						is_value = 0
			else:
				#
				# set the argument
				#
				self.argument_dict[last_parameter] = parameter
				is_value = 0
				last_parameter = ''
		#
		# check required settings
		#
		for params in self.required_dict.keys():
			required_value = self.required_dict[params]
			if required_value == 'false':
				#
				# required parameter not set
				#
				self.foundation.printError('Missing required parameter for ' + self.script_name + ' parameter: ' + params)
				sys.exit(-1)

		
		
