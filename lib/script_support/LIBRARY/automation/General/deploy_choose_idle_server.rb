################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

#  Create Script arguments in the comment block below.  Script arguments must have
###
# user:
#   name: Login for app server
# password:
#   name: Password app remote server
#   private: yes
# current_server_property:
#   name: Property that holds the package name
# url_check:
#   name: Test URL for load balancer
###
# Load the input parameters file and parse as yaml.
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle

#====================  User Portion of Script ==========================#

idle_server_prop = params["current_server_property"]

unless idle_server_prop.nil? || idle_server_prop.length < 2
  # Get a list of the servers and properties
  # Auth must be ssh, public key or username/pwd same on all target servers
  # List is [server_name, {property1=>value1, propery2=>value2 }]
  # Example
  hosts = []
  servers = get_server_list(params)
  servers.each do |server|
    hosts << server[0]  #Grab the Server Name and make the host array
  end
  write_to "Executing on Hosts: #{hosts.inspect}"

  set :user, params["user"]
  set :password, params["password"]

   # Issue wget to test page
   cmd = "wget -qO- #{params["url_check"]}"
   results = "Checking webserver file: #{params["url_check"]}"
   # Run the command directly on the localhost
   result = `#{cmd}`
   results += result + "\n"
   page_name = "ref_version.html"
   # Loop through each host
   idle_server = "none"
   hosts.each do |server|
     # Check Log to see which one got used
     role :all, server
     write_to "Testing Server: #{server}"
     params["sudo"] = "yes"
     cmd = "tail -5 /var/log/httpd/access_log | grep #{page_name}"
     begin
       answer = run_command(params, cmd, "", true)
       if answer.length > 20
         active_server = server
       else
         idle_server = server
       end
       results += answer + "\n"
     rescue RuntimeError => failure
       results += failure.message + "\n"
     else
       raise
     end
     roles[:servers_each].clear
  end
  write_to results
  unless idle_server == "none"
    # Take the found server and set the property flag
    #  (this signals to set the property to the server name)
    pflag = set_property_flag(idle_server_prop, idle_server)
    success = ""
  else
    success = "Command_Failed: No idle server found"
  end
  
else
  success = "zzzz"
  results = "No server property argument specified"
end

# Test the results for success or failure
unless results.include?(success)
  write_to "Success test, looking for #{success}: Command_Failed (term not found)"
else
  write_to "Success test, looking for #{success}: Success "
end

# Close the output file
@hand.close
