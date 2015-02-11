################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class BladelogicScriptsController < ApplicationController
  include ControllerSharedScript

  private 
  
    def bladelogic?
      true
    end

    def use_template
     'bladelogic'
    end
end
