################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ComponentProperty < ActiveRecord::Base

  attr_accessible :insertion_point, :component_id, :property_id

  belongs_to :component
  belongs_to :property

  belongs_to :active_property, :class_name => "Property",
                               :foreign_key => "property_id",
                               :conditions => {"properties.active" => true}

  acts_as_list :scope => :component_id

  scope :by_property_and_component, ->(property_id, component_id) { where(property_id: property_id, component_id: component_id) }

  def insertion_point
    position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end
end
