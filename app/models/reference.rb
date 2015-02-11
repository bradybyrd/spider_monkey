################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class Reference < ActiveRecord::Base
  # References is a keyword in SQLServer and some queries fail because of it
  # Explicitly specifying table_name to avoid conflict
  self.table_name = "package_references"
  include PropertyValuesFromApi

  validates :name, presence: true, uniqueness: { scope: :package_id }, length: { in: 0..255 }
  validates :uri, presence: true, length: { in: 0..255 }
  validates :server_id, presence: true
  validates :package, presence: true
  validates :resource_method, inclusion: { in: %w(File) }, length: { in: 0..255 }
  validate :package_id_not_changed

  belongs_to :package
  belongs_to :server
  has_many :property_values, as: :value_holder, dependent: :destroy, conditions: { deleted_at: nil}

  attr_accessible :name, :uri, :server_id, :package_id, :properties_with_values

  # if the validations all went well, we can update the properties
  after_save :update_properties_with_values

  attr_accessor :properties_with_values,
    :properties_with_values_sanitized,
    :properties_with_values_lookup_failed

  def properties_that_can_be_overridden
    package.properties.active - overridden_properties
  end

  def properties
    package.properties
  end

  def available_servers_for(user)
    servers = Server.by_ability(:list, user) << self.server
    servers.compact.uniq
  end

  private

  def lookups_succeeded
    errors.add(:properties_with_values, "could not be found. Check that the property and the values are valid for this package.") if properties_with_values_lookup_failed
  end

  def overridden_properties
    property_values.includes(:property).map(&:property)
  end

  def package_id_not_changed
    if package_id_changed? && self.persisted?
      errors.add(:package_id, I18n.t('package.errors.package_id_change_not_allowed'))
    end
  end
end
