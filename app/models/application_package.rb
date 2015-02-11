################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ApplicationPackage < ActiveRecord::Base
  include PropertyValuesFromApi

  concerned_with :import_app_application_packages

  belongs_to :app
  belongs_to :package

  has_many :property_values, :as => :value_holder, :dependent => :destroy, :conditions => 'deleted_at IS NULL'
  has_many :current_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NULL'
  has_many :deleted_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NOT NULL'

  attr_accessible :app_id, :name, :package_id, :insertion_point, :position, :different_level_from_previous, :insertion_point, :properties_with_values
  attr_accessor :properties_with_values,
    :properties_with_values_sanitized,
    :properties_with_values_lookup_failed

  after_save :update_properties_with_values

  validates :package, presence: true
  validates :package_id,
            :presence => true,
            :uniqueness => { scope: :app_id, message: 'has already been added' }
  validates :app,
            :presence => true
  validate :property_values_exist

  delegate :name, to: :package
  delegate :properties, to: :package, allow_nil: true

  acts_as_list :scope => :app

  scope :in_order, order(:position)


  scope :by_application_and_package_names, lambda { |application_name, package_name|
    {
        include: [:app, :package],
        conditions: ["(apps.name LIKE ? OR apps.name LIKE ?) AND packages.name LIKE ?", application_name, "#{application_name}_|%", package_name]
    }
  }

  def property_values_exist
    unless property_value_names_exist?
      self.errors.add(:properties_with_values, I18n.t('application_package.errors.property_value_names_dont_exist'))
    end
  end

  def property_value_names_exist?
    property_value_names.all? do |property_name|
      find_property_by_name(property_name).present?
    end
  end

  def property_value_names
    (properties_with_values || {}).keys
  end
end
