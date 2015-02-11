################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PlansSweeper < ActionController::Caching::Sweeper
  observe Plan

  # If our sweeper detects that a plan was created call this
  def after_create(plan)
    expire_cache_for(plan)
  end

  # If our sweeper detects that a plan was updated call this
  def after_update(plan)
    expire_cache_for(plan)
  end

  # If our sweeper detects that a plan was deleted call this
  def after_destroy(plan)
    expire_cache_for(plan)
  end

  private
  def expire_cache_for(plan)
    # Expire the index page now that we added a new plan
    #expire_page(:controller => 'plan', :action => 'index')

    # Expire a fragment
    #expire_fragment('')
  end

end
