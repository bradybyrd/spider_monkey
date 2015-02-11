################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# app_server_host:
#   name: host to copy to (user@host)
# base_path:
#   name: base path the files_to_copy list starts from
# files_to_copy:
#   name: name of files to copy (path-from base, semi-colon separated)
# target_files:
#   name: places to copy files to (full-path, semi-colon separated)
###
# Copies files from staging area (on local host)
# To app server host deploy directory
# Assumes ssh keys have been shared between machines
# Load the input parameters file and parse as yaml
params = load_input_params(ENV["_SS_INPUTFILE"])
params["direct_execute"] = true #flag for local execution
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

# ========= Put User Script Items here =========#

host_parts = params["app_server_host"].split("@")
params["user"] = host_parts[0]

src_host = ""
tgt_host = params["app_server_host"] == "localhost" ? "" : (params["app_server_host"] + ":")

targets = params["target_files"].split(";")
single_dest = true if targets.size == 1  #Flag if you want all files to go to the same place
files = params["files_to_copy"].split(";")


if single_dest || targets.size == files.size
  result = "SCP File Copy (#{files.size.to_s} to do)\n"
  files.each_with_index do |fil, idx|
    target = single_dest ? targets[0] : targets[idx]
    cmd = "scp -B #{src_host + params["base_path"]}/#{fil.strip} #{tgt_host + target}"
    write_to "Running: #{cmd}"
    result += run_command(params, cmd, "")
  end
  # Apply success or failure criteria
  error_phrase = "Permission denied"  
  if result.index(error_phrase).nil?
    write_to "Success - term not found: #{error_phrase}\n"
  else
    write_to "Command_Failed - found: [#{error_phrase}]\n"
  end

else
  result = "Command_Failed - Files to copy and target destinations are not the same size"
end

#Close the file
@hand.close
