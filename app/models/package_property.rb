################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PackageProperty < ActiveRecord::Base

  attr_accessible :insertion_point, :package_id, :property_id

  belongs_to :package
  belongs_to :property

  belongs_to :active_property, :class_name => "Property",
                               :foreign_key => "property_id",
                               :conditions => {"properties.active" => true}

  acts_as_list :scope => :package_id

  scope :by_property_and_package, ->(property_id, package_id) { where(property_id: property_id, package_id: package_id) }

  def insertion_point
    position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end
end
