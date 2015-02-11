################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class CapistranoScriptsController < ApplicationController
  include ControllerSharedScript

  around_filter :timeout, :only => [:test_run]

  protected

    def timeout
      #SystemTimer.timeout(30) do
      Timeout.timeout(300) do
        yield
      end
    end

  private

    def bladelogic?
      false
    end

    def capistrano?
      true
    end
    
    def hudson?
      false
    end

    def use_template
     'capistrano'
    end
end
