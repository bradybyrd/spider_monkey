################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class InstanceReference < ActiveRecord::Base
  validates :name, presence: true
  validates :uri, presence: true
  validates :server, presence: true
  validates :resource_method, inclusion: { in: %w(File) }

  belongs_to :reference
  belongs_to :package_instance
  belongs_to :server

  has_many :property_values, :as => :value_holder, :dependent => :destroy, :conditions => 'deleted_at IS NULL'
  has_many :current_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NULL'
  has_many :deleted_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NOT NULL'

  has_many :properties, :through => :property_values

  attr_accessible :name, :url, :server_id

  ## mainly to support rest client
  def find_property_by_name( prop_name )
    self.properties.find { | prop | prop.name == prop_name }
  end

end
