################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ScriptArgumentToPropertyMap < Satpm
  belongs_to :script_argument, :polymorphic => true
  belongs_to :property
  belongs_to :value_holder, :polymorphic => true
  
  scope :for_components, where("satpms.value_holder_type" => 'InstalledComponent')
  scope :for_servers, where(:value_holder_type => 'Server')
  scope :for_server_aspects, where(:value_holder_type => 'ServerAspect')
  
  scope :with_components, lambda {|component_ids|
      joins("INNER JOIN properties ON satpms.property_id = properties.id " + 
                "INNER JOIN installed_components ON satpms.value_holder_id = installed_components.id " +
                "INNER JOIN application_components ON installed_components.application_component_id = application_components.id " + 
                "INNER JOIN components ON application_components.component_id = components.id").
      where("components.id" => component_ids)
  }

  scope :property_id_equals, lambda{ |id|
    where(:property_id => id)
  }

  attr_accessible :property, :value_holder
  delegate :name, :to => :property, :prefix => true, :allow_nil => true

  def for_component?
    value_holder_type == "InstalledComponent"
  end

  def component_id
    value_holder.component_id if for_component?
  end
  
  def application_environment_id
    value_holder.application_environment_id if for_component?
  end
  
  def app_id
    value_holder.app_id if for_component?
  end

  def server_id
    value_holder_id if value_holder_type == "Server"
  end

  def server_aspect_id
    value_holder_id if value_holder_type == "ServerAspect"
  end

end
