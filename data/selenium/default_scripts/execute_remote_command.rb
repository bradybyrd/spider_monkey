################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###
# hosts:
#   name: IP address remote server
# user:
#   name: Login for remote server
# password:
#   name: Password for remote server
# command:
#   name: Name of command
# sudo:
#   name: Use sudo? (yes or no/blank)
###

task :execute do
  set :user, ENV["USER"]
  set :password, ENV["PASSWORD"]
  method = ENV["SUDO"] == 'yes' ? :sudo : :run
  invoke_command(ENV["COMMAND"], :via => method)
end
