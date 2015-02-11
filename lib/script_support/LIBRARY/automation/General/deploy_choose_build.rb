################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# build_server:
#   name: Build Server
# user:
#   name: Build Server User
# password:
#   name: Build Server Password
#   private: yes
# file_selector:
#   name: Filter for file
# target_dir:
#   name: Directory in which to run command
# recent_file_property:
#   name: Property to put the selected package name
###
# Load the input parameters file and parse as yaml
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

#==============  User Portion of Script ==================

# Run the command on the build server
#  Chooses the most recent file based on the filter in the directory
#  First run a command to show the listing
#  Then run again with the filter to get 1 file
#  because we may get extra information from script execution and the ls command,
#  I add a unique flag to the results (SS_SelectedFile) and I know the file I 
#  want is on the line after that string

property_name = params["recent_file_property"]
unless property_name.nil? || property_name.length < 2

  hosts = [params["build_server"]]
  write_to "Executing on Hosts: #{hosts.inspect}"
  role :all do # This tells Capistrano to perform the action on an array of hosts
   hosts
  end

  # Show them the listing
  path = params["target_dir"]
  write_to "Selecting file into property: #{property_name}"
  write_to "Listing files by date:"
  cmd = "ls -ltr #{path}/#{params["file_selector"]}"
  result = run_command(params, cmd, '', true)

  # Grab the file (the most recent file by date)
  start_flag = "SS_SelectedFile"
  write_to "Selected File:"
  result += start_flag + "\n"
  cmd = "ls -tr #{path}/#{params["file_selector"]} | tail -1"
  found_file = run_command(params, cmd, '', true) # the true argument returns just the result without extras
  if found_file.length > 4 then
    pos1 = found_file.index(path)
    pos2 = found_file.index("\n")
    result += "Search Result: #{found_file}\n"
    unless pos1.nil? || pos2.nil?
      new_file = found_file.slice((pos1+path.length)..(pos2-1))
      new_file.gsub!("/","").strip!
      write_to "  Filename: #{new_file}\n"
      # Take the found file name and set the property flag
      #  (this signals to set the property "deploy package" to the new_file name)
      pflag = set_property_flag(property_name, new_file)

      params["success"] = ""
    else
      write_to "Command_Failed:  couldn't find selected file"
    end
  else
    write_to "No File found with ls -l #{params["file_selector"]}"
    params["success"] = "ZZ-BadFilter"
  end
else
  result = "Command_Failed - No property name specified in arguments"
end

# Apply success or failure criteria
if result.index(params["success"]).nil?
  write_to "Command_Failed - no file found\n"
else
  write_to "Success - found file: #{found_file}\n"
end

#Close the file
@hand.close
