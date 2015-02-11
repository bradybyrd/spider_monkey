################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# ss_deploy_setup_apache
#  Creates a new virtual host entry on the streamdeploy.conf file
# BJB 1-3-11 Streamstep, Inc.
###
# application_dir:
#   name: Application deploy directory
# server_port:
#   name: Port to serve the site
###
# Load the input parameters file and parse as yaml
params = load_input_params(ENV["_SS_INPUTFILE"])
# Create a new output file and note it in the return message: sets @hand
create_output_file(params) #sets the @hand file handle
params["sudo"] = "yes" # Need sudo for user actions

#==============  User Portion of Script ==================

unless params["temp Server"].nil?
  hosts = [params["temp Server"]]
  write_to "Executing on Hosts: #{hosts.inspect}"
  role :all do # This tells Capistrano to perform the action on an array of hosts
    hosts
  end

  params["user"] = params["Deploy User"]
  params["password"] = params["Deploy pwd"]
  port = params["server_port"]
  app_dir = params["application_dir"]
  vhost <<-END
  
  <VirtualHost *:#{port}>
      ServerName ec2-75-101-221-171.compute-1.amazonaws.com
      DocumentRoot #{app_dir}
      <Directory #{app_dir}>
         AllowOverride all
         Options -MultiViews
      </Directory>
  </VirtualHost>
  
  END
  
  cmd = "echo #{vhost} >> /etc/httpd/conf.d/streamdeploy.conf"
  result = run_command(params, cmd, "")
  # Apply success or failure criteria
  success = ""
  if result.index(success).nil?
    write_to "Command_Failed - term #{success} found\n"
  else
    write_to "Success - found term: #{success}\n"
  end
else
   write_to "Command_Failed - No server specified"
end
#Close the file
@hand.close
