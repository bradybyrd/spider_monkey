################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ServerAspectFacade

  def self.included(target)
    target.extend ClassMethods
  end

  module ClassMethods
    def name
      self.to_s
    end
  end

  def server_level
    self.class
  end

  def level_name
    self.class.to_s.pluralize.underscore.titleize
  end

  def properties
    (self.class == Server) ? super : []
  end

  def property_values
    (self.class == Server) ? super : []
  end

  def path
    [self]
  end

  def path_string
    name
  end
  
  def type_and_id
    "#{self.class}::#{id}"
  end

end
