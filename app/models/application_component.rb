################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ApplicationComponent < ActiveRecord::Base
  belongs_to :app
  belongs_to :component

  has_many :installed_components, :dependent => :destroy
  has_many :application_environments, :through => :installed_components
  has_many :property_values, :as => :value_holder, :dependent => :destroy
  has_many :component_templates, :dependent => :nullify
   
  has_many :package_template_components, :dependent => :nullify
  has_many :package_template_items, :through => :package_template_components
  has_many :versions
  has_many :application_component_mappings, :dependent => :destroy
  
  attr_accessible :name, :component_id, :insertion_point, :position, :different_level_from_previous, :insertion_point
  
  validates :component,
            :presence => true
  validates :app,
            :presence => true

  delegate :name, :to => :component
  delegate :properties, :to => :component

  acts_as_list :scope => :app
  
  scope :in_order, order(:position)
  
 scope :by_application_and_component_names, lambda { |application_name, component_name| 
    {
      :include => [:app, :component],
      :conditions => ["(apps.name LIKE ? OR apps.name LIKE ?) AND components.name LIKE ?", application_name, "#{application_name}_|%", component_name]
    }
  } 
  def insertion_point
    self.position
  end

  def insertion_point=(new_position)
    self.insert_at(new_position.to_i)
  end

  def literal_property_value_for(given_property)
    res = nil
    res = if property_values.find_by_property_id(given_property.id).try(:value).present? && properties.find_by_id(given_property.id).present?
       property_values.find_by_property_id(given_property.id).try(:value) 
    else
      given_property.default_value
    end
    res
  end
  
  def current_property_values
    # Placeholder for request level properties BJB 11-23-11
    property_values
  end
end
