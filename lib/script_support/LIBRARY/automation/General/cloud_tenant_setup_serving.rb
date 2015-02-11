################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# host_name:
#   name: IP address remote server
# user:
#   name: Login for remote server
# password:
#   name: Password for remote server
#   private: yes
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle
role :all, params["host_name"] # Must be set for Capistrano

# ==============  Build User Script Here ===============


client_name = params["New Client Name"]
if(client_name.length < 2 || client_name.nil?)
  write_to "Command_Failed - No Client Name set"
else
  # Works: /mnt/.ss/setup setup_serving <client_name> dev
  cmd = "/ss/.support/setup.rb setup_serving #{client_name}"
  # Run the command on the server
  results = run_command(params, cmd, "")
  key_phrase = "serving on port: "
  ipos = results.index(key_phrase)
  new_port = ipos > 0 ? results.slice((ipos + key_phrase.length)..(ipos + key_phrase.length + 4)) : "80"
  pflag = set_property_flag("temp Port", new_port.strip)
  write_to "Serving on port #{new_port}"
  # Test the results for success or failure
  success = "serving on port:"
  if results.include?(success)
    write_to "Success test, looking for #{success}: Success"
  else
    write_to "Success test, looking for #{success}: Command_Failed (term not found)"
  end
end
# Close the output file
@hand.close
