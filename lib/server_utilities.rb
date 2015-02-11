################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ServerUtilities

  def has_components_on_app?(app)
    return false if installed_components.empty? and server_aspects.empty?
    return true if installed_components.any? { |ic| ic.app == app }
    aspects_below.any? { |aspect| aspect.has_components_on_app? app }
  end

  def aspects_below
    server_aspects.map { |sa| sa.aspects_below.unshift(sa) }.flatten
  end
  
end
