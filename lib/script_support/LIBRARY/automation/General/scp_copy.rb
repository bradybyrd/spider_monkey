################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# source_host:
#   name: host to copy from (user@host or localhost)
# target_host:
#   name: host to copy to (user@host or localhost)
# base_path:
#   name: base path the files_to_copy list starts from
# files_to_copy:
#   name: name of files to copy (path-from base, semi-colon separated)
# target_path:
#   name: place to copy files to (uses relatice paths from files_to_copy)
# password:
#   name: password if necessary
#   private: yes
###
# Uses Capistrano to go to a remote host and then
# copy files to another host
# Assumes ssh keys have been shared between machines
# if the source_host or target is localhost
# it will work directly
# Load the input parameters file and parse as yaml
params = load_input_params(ENV["_SS_INPUTFILE"])

host_parts = params["source_host"].split("@")
params["user"] = host_parts[0]

#set the role on the server
role :all, host_parts[1]

src_host = ""
src_host = (params["source_host"] + ":") if (params["source_host"] != "localhost" && params["target_host"] == 'localhost')
tgt_host = params["target_host"] == "localhost" ? "" : (params["target_host"] + ":")

target = params["target_path"].strip
files = params["files_to_copy"].split(";")

# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

result = "SCP File Copy (#{files.size.to_s} to do)\n"
files.each_with_index do |fil, idx|
  cmd = "scp -B #{src_host + params["base_path"]}/#{fil.strip} #{tgt_host + target}/#{fil.strip}"
  result += run_command(params, cmd, "")
end
# Apply success or failure criteria
error_phrase = "Permission denied"  
if result.index(error_phrase).nil?
  write_to "Success - term not found: [#{error_phrase}]\n"
else
  write_to "Command_Failed - found term: #{error_phrase}]\n"
end


#Close the file
@hand.close
