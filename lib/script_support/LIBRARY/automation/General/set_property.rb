################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# file_selector:
#   name: Filter for file
# target_dir:
#   name: Directory in which to run command
###
# Load the input parameters file and parse as yaml
params = load_input_params(ENV["_SS_INPUTFILE"])
# Flag the script for direct execution
params["direct_execute"] = true
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

#==============  User Portion of Script ==================

# Run the command directly on the localhost
#  Chooses the most recent file based on the filter in the directory
#  First run a command to show the listing
#  Then run again with the filter to get 1 file
#  because we may get extra information from script execution and the ls command,
#  I add a unique flag to the results (SS_SelectedFile) and I know the file I 
#  want is on the line after that string

# Show them the listing
write_to "Listing files by date:"
cmd = "ls -ltr #{params["target_dir"]}/#{params["file_selector"]}"
result = run_command(params, cmd, '', true)

# Grab the file (the most recent file by date)
start_flag = "SS_SelectedFile"
write_to "Selected File:"
result += start_flag + "\n"
cmd = "ls -tr #{params["target_dir"]}/#{params["file_selector"]} | tail -1"
found_file = run_command(params, cmd, '', true) # the true argument returns just the result without extras
if found_file.length > 4 then
  result += (start_flag + found_file + "#{start_flag}End\n")
  pos1 = result.index(start_flag)
  pos2 = result.index(start_flag + "End")
  new_file = result.slice(pos1..(pos2-1))
  new_file.gsub!(start_flag, "").gsub!("\n","").gsub!(params["target_dir"] + "/", "")

  # Take the found file name and set the property flag
  #  (this signals to set the property "deploy package" to the new_file name)
  pflag = set_property_flag("deploy package", new_file)

  params["success"] = ""
else
  write_to "No File found with ls -l #{params["file_selector"]}"
  params["success"] = "ZZ-BadFilter"
end

# Apply success or failure criteria
if result.index(params["success"]).nil?
  write_to "Command_Failed - no file found\n"
else
  write_to "Success - found file: #{found_file}\n"
end

#Close the file
@hand.close
