################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PropertyValue < ActiveRecord::Base
  
  MASK_CHARACTER = "*"
  acts_as_audited
  belongs_to :property
  belongs_to :value_holder, :polymorphic => true

  validates :property_id, presence: true

  validates :value_holder, :presence => true

  scope :active, includes(:property).where('properties.active = ?', true)

  scope :upto_date, lambda { |date_of_change| where("property_values.created_at <= ? ", date_of_change) }

  scope :in_order, order("value_holder_type, value_holder_id, created_at DESC")

  scope :limited, lambda { |limit_val|
    { :order => "created_at DESC", :limit => limit_val }
  }
  
  scope :values_for_app_comp, lambda { |app_comp_id| where("value_holder_id = ? AND value_holder_type = 'ApplicationComponent'", app_comp_id)  }

  delegate :name, :to => :property

  attr_accessible :property_id, :value, :value_holder_id, :value_holder_type, :created_at, :locked
  
  def holder
    value_holder_type.constantize.find(value_holder_id)
  end
  
  def value_label
    type_label = "none"
    cur = holder
    type_label =  "(property-global)" if value_holder_type == "Property"
    unless holder.nil?
      inactive = deleted_at.nil? ? "" : "-inactive"
      case value_holder_type
      when "InstalledComponent"
        type_label =  "#{cur.application_component.app.name} - #{cur.component.name} - #{cur.application_environment.environment.name} (installed component)"
      when "Server"
        type_label =  "#{cur.name} (server)"
      when "ServerAspect"
        type_label =  "#{cur.name} (server-level)"
      when "Reference" 
        type_label =  "#{cur.package.name} #{cur.name} (package reference)"
      when "PackageInstance" 
        type_label =  "#{cur.package.name} #{cur.name} (package instance)"
      when "InstanceReference" 
        type_label =  "#{cur.package_instance.package.name} #{cur.package_instance.name} #{cur.name} (package instance reference)"
      when "ApplicationPackage"
          type_label =  "#{cur.app.name} #{cur.name} (application package)"
      when "ApplicationComponent"
        type_label =  "#{cur.app.name} - #{cur.component.name} (application component)"
      end
    end
    type_label + inactive
  end
  
  def display_value
    if self.property.is_private?
      self.mask_private_value(self.value)
    else
      self.value  
    end
  end
  
  protected 
  
  def mask_private_value(content_text = "")
    PropertyValue::MASK_CHARACTER * content_text.to_s.size
  end
end
