################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PackageTemplateItem < ActiveRecord::Base
    
  attr_accessible :insertion_point
  
  acts_as_list :scope => :package_template
  
  belongs_to :component_template
  
  HUMANIZED_ATTRIBUTES = {
    :application_component_ids => "Component List"
  }
  
  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end 
  
  ItemTypes = [['Component Instance', 2], ['Command', 1]]
  
  BLComponentInstances = (1..5).to_a.collect { |i| ["BL Component Instance #{i}", 1]}
  
  SingleUserMode = List.get_list_items("SingleUserMode")
  Reboot = List.get_list_items("Reboot")
  ActionOnFail = List.get_list_items("ActionOnFail")
  
  belongs_to :package_template
  
  validates :package_template_id, :presence => true
  validates :name, :presence => true
  validates :item_type, :presence => true
  validates :component_template_id, :presence => {:if => Proc.new { |pti| pti.item_type == 2 }}
  validates :description,:length => {:maximum => 255, :allow_nil => true}
  
  serialize :properties, Hash
  serialize :commands,   Hash
  
  has_many :package_template_components, :dependent => :destroy
  has_many :application_components, :through => :package_template_components
  
  attr_accessor :command, :undo_command, :should_save, :single_user_mode, :reboot, :action_on_fail
    
  attr_accessor :target, :property_2, :property_3, :property_4, :property_5, :property_6, :application_component_ids
  
  scope :component_instances, where( :item_type => 2 )
  
  before_save :stitch_command, :stitch_properties
  after_create :insert_at_correct_position
  
  def stitch_command
    write_attribute(:commands, { :command => command, 
                                 :undo_command => undo_command, 
                                 :single_user_mode => single_user_mode, 
                                 :reboot => reboot, 
                                 :action_on_fail => action_on_fail  
                               })
  end
  
  def stitch_properties
    write_attribute(:properties, {:target => target})
  end
  
  def item_type_name
    #item_type == 2 ? "Component Instance" : "Commmand"  # Error waiting to happen
    item_type > 0 ? ItemTypes[2-item_type][0] : "unknown"
  end
  
  def insertion_point
    position
  end

  def insertion_point=(new_position)
    insert_at(new_position.to_i)
  end
  
  def changed?
    stitch_command
    stitch_properties
    super
  end
  private
  
  def insert_at_correct_position
    insert_at(package_template.template_items.count)
  end
  
end
