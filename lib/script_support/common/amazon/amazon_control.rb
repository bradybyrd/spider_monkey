################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# BJB 4/28/10
#  Lists Rightscale images using rightscale gem
require 'rubygems'
require 'right_aws'
require "#{File.dirname(__FILE__)}/amazon_lib.rb"

#    ------------  Main Proc  -----------------
if ARGV.size > 0
  case ARGV[0]
    when 'list_instances'
      list_instances
    when 'instance_status'
      instance_status(ARGV[1]) if ARGV.size > 1
    when 'list_images'
      list_images
    when 'launch_image'
      if ARGV.size > 2
        launch_image(ARGV[1], ARGV[2])
      end
    when 'delete_instance'
      if ARGV.size == 2
        delete_instance(ARGV[1])
      end
    else
      syntax_msg
  end
else
  syntax_msg
end
