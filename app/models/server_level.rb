################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ServerLevel < ActiveRecord::Base
  include QueryHelper

  has_many :server_aspects, :dependent => :destroy
  has_many :server_level_properties, :dependent => :destroy
  has_many :properties, :through => :server_level_properties
  has_many :property_values, :as => :value_holder, :dependent => :destroy
  has_many :current_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NULL'
  has_many :deleted_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NOT NULL'

  attr_accessible :name, :description

  validates :name,
            :presence => true,
            :uniqueness => {:case_sensitive => false}

  normalize_attributes :name

  acts_as_list

  scope :in_order, order('position')
  scope :name_order, order('name asc')
  scope :via_team, where("team_id IS NOT NULL")

  def has_server_aspects?
    !(server_aspects.empty? || server_aspects.all? { |server_aspect| server_aspect.new_record? })
  end

  def potential_parents
    if first?
      Server.active + ServerGroup.active
    elsif higher_item.present?
      higher_item.server_aspects + higher_item.potential_parents
    else
      []
    end
  end

  def grouped_potential_parents
    potential_parents.group_by { |p| p.level_name }.map { |lvl, servers| [lvl, servers.sort_by(&:name)] }
  end

  def underscored_name
    name.underscore.gsub(/\W+/, '_')
  end

  def update_property_value_for(property, value)
    property.update_value_for_object(self, value)
  end

  def property_value_for(given_property, user = nil)
    self.current_property_values.first(:conditions => { :property_id => given_property.id })
  end

  def SUPPRESS_literal_property_value_for(given_property, user = nil)
    editable = user.can_see_property?(given_property) unless user.nil?
    if user.nil? || editable
      property = if current_property_values.find_by_property_id(given_property.id).try(:value).present?
         current_property_values.find_by_property_id(given_property.id).try(:value)
      else
         given_property.value_for_property.try(:value)
      end
      property
    else
      "-private-"
    end
  end

end

