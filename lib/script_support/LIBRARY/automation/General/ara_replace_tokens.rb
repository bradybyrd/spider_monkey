################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# ara_config_file:
#   name: ara application config file (full path)
# ara_config_newfile:
#   name: name for the modified config file (full path)
# ara_tokens:
#   name: name of files to copy (full-path, semi-colon separated)
# ara_token_value1:
#   name: value for first token
# ara_token_value2:
#   name: value for token 2
# ara_token_value3:
#   name: value for token 3
# ara_token_value4:
#   name: value for token 4
###
# Opens the local staged version of the configuration
# substitutes property values for ara tokens
# saves as a new file name

# Load the input parameters file and parse as yaml
params = load_input_params(ENV["_SS_INPUTFILE"])
params["direct_execute"] = true
#set the role on the server
#role :all, host_parts[1]
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

# ========= Put User Script Items here =========#

def ara_token(token)
  "${ph:#{token}}"
end

host_parts = params["ssh_staging_host"].split("@")
params["user"] = host_parts[0]

tokens = params["ara_tokens"].split(";")
write_to("Tokens to replace: #{tokens.inspect}")
write_to("Opening config file: #{params["ara_config_file"]}")
config = File.open(params["ara_config_file"]).read
write_to "============== Original Config ================="
write_to config + "\n"
tokens.each_with_index do |fil, idx|
  prop = params["ara_token_value#{idx.to_s}"]
  if config.include?(ara_token(token))
    unless prop.nil?
      config.gsub!(ara_token(token), prop)
      write_to("Replacing: #{token} with #{prop}")
    else
      write_to("Replacing: #{token} - No value provided")
    end
  else
    write_to("Command_Failed - Token: #{token} - not found")
  end
end
write_to "============== Modified Config ================="
write_to config + "\n"
write_to "Saving new config: #{params["ara_config_newfile"]}"
newfil = File.open(params["ara_config_newfile"], "w+")
newfil.print config
newfil.close

  # Apply success or failure criteria
error_phrase = "Permission denied"  
if result.index(error_phrase).nil?
  write_to "Success - found term: #{params["success"]}\n"
else
  write_to "Command_Failed - term not found: [#{params["success"]}]\n"
end

#Close the file
@hand.close
