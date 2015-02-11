################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class StepsSweeper < ActionController::Caching::Sweeper
  observe Step

  # If our sweeper detects that a step was created call this
  def after_create(step)
    expire_cache_for(step)
  end

  # If our sweeper detects that a step was updated call this
  def after_update(step)
    expire_cache_for(step)
  end

  # If our sweeper detects that a step was deleted call this
  def after_destroy(step)
    expire_cache_for(step)
  end

  private
  def expire_cache_for(step)
    # Expire the index page now that we added a new step
    #expire_page(:controller => 'step', :action => 'index')

    # Expire a fragment
    #expire_fragment('')
  end

end
