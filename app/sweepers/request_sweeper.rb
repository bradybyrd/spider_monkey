################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class RequestSweeper < ActionController::Caching::Sweeper
  observe Request

  # If our sweeper detects that a request was created call this
  def after_create(request)
    expire_cache_for(request)
  end

  # If our sweeper detects that a request was updated call this
  def after_update(request)
    expire_cache_for(request)
  end

  # If our sweeper detects that a request was deleted call this
  def after_destroy(request)
    expire_cache_for(request)
  end

  private
  def expire_cache_for(request)
    # Expire the index page now that we added a new request
    #expire_page(:controller => 'requests', :action => 'index')

    # Expire a fragment
    #expire_fragment('')
  end

end
