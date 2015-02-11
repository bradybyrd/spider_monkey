################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PackageTemplate < ActiveRecord::Base
  
  belongs_to :app
  
  validates :app_id, :presence=> true
  validates :name, 
            :presence=> true,
            :uniqueness => {:unless => Proc.new { |pt| pt.name.blank? }, :scope => :app_id}
  validates :version, :presence=> true
  
  has_many :package_template_items, :dependent => :destroy, :order => 'package_template_items.position ASC'
  has_many :steps
  
  accepts_nested_attributes_for :package_template_items, :reject_if => proc { |attributes| attributes['should_save'] == 'no' }
  
  scope :active, where("package_templates.active" => true)
  scope :inactive, where("package_templates.active" => false)
  
  def template_items
    package_template_items
  end
  
  def item_count
    template_items.size == 1 ? 1 : template_items.size
  end
  
  def component_name
    names = []
    template_items.select { |template_item| template_item.item_type == 2 }.each do |component_instance_template|
      names << component_instance_template.component_template.application_component.try(:component).try(:name)
    end 
    names.uniq.to_sentence
  end
  
  def build_blpackage_params(params)
    #BJB 10-2-10
    # Build Input File information for script call
    params["SS_package_name"] = name
    params["SS_version"] = version
    params["SS_application"] = app.name
    params["SS_user"] = active_user
    # Add SS_Props - application, env etc
    template_items.each_with_index do |item, idx|
      params["SS_item#{idx.to_s}_name"] = item.name
      params["SS_item#{idx.to_s}_type"] = item.item_type_name
      params["SS_item#{idx.to_s}_component_name"] = item.component_template.name if item.item_type_name == "Component Template"
      params["SS_item#{idx.to_s}_commands"] = AutomationCommon.hash_string(item.commands) if item.item_type_name == "Command"
      params["SS_item#{idx.to_s}_properties"] = AutomationCommon.hash_string(item.properties)
    end
    params
  end
          
  def active_user
    User.current_user.nil? ? "Unknown User" : User.current_user.name
  end
    
end
