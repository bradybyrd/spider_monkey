################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

#  Create Script arguments in the comment block below.  Script arguments must have
###
# success:
#   name: text to look for in the webpage
# page_to_test:
#   name: url on the site (relative)
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
params["direct_execute"] = true
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle
#set the role on the server
#  Disable for this example -role :all, params["servers"]

#====================  User Portion of Script ==========================#

  page = params["page_to_test"]
  protocol = "http://"
  host = params["External DNS"]
  port = params["temp Port"]
  success = params["success"]
  results = "Testing websites\n"
  # Build wget Command
  results += "------ Server: #{page} --------\n"
  command = "wget -qO- #{protocol}#{host}:#{port}/#{page}"
    # Now Run the Command
    cur_result = `#{command}`
    # Test the results for success or failure
    unless cur_result.include?(success)
      results += "Success test, looking for #{success}: Command_Failed (term not found)\n"
    else
      results += "Success test, looking for #{success}: Success \n"
    end
    results += "<pre>#{cur_result.slice(0..2000)}</pre>"
  write_to results

# Close the output file
@hand.close
