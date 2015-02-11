################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

###  Streamstep Versions Checker #######
# 1-4-11 BJB 
Lil = "-------------------------------------------------------\n"
Sep = "=======================================================\n"
result = Sep + "Streamstep Deploy Version Check\n" + Sep
# Apache Version
result += "Apache:\n"
result += `httpd -v`
# RVM
result += "#{Lil}RVM Environment:\n"
result += "RVM Type: "
result += `type rvm | head -1`
result += "Current Gemset: "
result += `rvm gemset name`
result += "Gemsets available: "
result += `rvm gemset list`
# Ruby Version
result += "#{Lil}Ruby:\n"
result += `ruby -v`
# Ruby Gems
result += "#{Lil}Gem Environment:\n"
result += `gem list`

# MySQL
result += "#{Lil}MySQL:\n"
result += `mysql --version`
# SQLPlus
result += "#{Lil}Oracle Client:\n"
result += `sqlplus -v`
# Git
result += "#{Lil}Git:\n"
result += `git --version`
#
puts result

result = Sep + "Apache Configuration\n" + Sep
result += `cat /etc/httpd/conf.d/streamdeploy.conf`
