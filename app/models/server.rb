################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
require 'permission_scope'

class Server < ActiveRecord::Base
  include SoftDelete
  include ServerAspectFacade
  include ServerUtilities
  include QueryHelper
  include FilterExt
  include PermissionScope

  attr_accessor :check_permissions

  attr_accessible :name, :dns, :ip_address, :os_platform, :environment_ids,:server_group_ids, :property_ids, :active

  # TODO: RJ: Rails 3: Log Activity plugin not compatible with rails 3
  #log_activities

  paginate_alphabetically :by => :name

  has_many :environment_servers, :dependent => :destroy, :conditions => 'environment_servers.server_aspect_id is NULL'
  has_many :environments,             through: :environment_servers, :before_remove => :validate_environment_removal
  has_many :application_environments, through: :environments
  has_many :assigned_apps,            through: :application_environments

  has_many :server_aspects, :as => :parent, :dependent => :destroy
  has_many :property_values, :as => :value_holder, :dependent => :destroy, :conditions => 'deleted_at IS NULL'
  has_many :current_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NULL'
  has_many :deleted_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NOT NULL'

  has_and_belongs_to_many :server_groups
  has_and_belongs_to_many :installed_components
  has_and_belongs_to_many :properties, conditions: { 'properties.active' => true }

  validates_with PermissionsPerEnvironmentValidator

  validates :name,
            :presence => true,
            :uniqueness => {:case_sensitive => false}
  validates_length_of :name, maximum: 255

  normalize_attributes :name

  scope :via_team, where(" team_id IS NOT NULL ")

  scope :id_equals, lambda{ |ids|
    where("servers.id" => ids)
  }

  scope :filter_by_name, lambda { |filter_value| where("LOWER(servers.name) like ?", filter_value.downcase) }

  is_filtered cumulative: [:name], boolean_flags: {default: :active, opposite: :inactive}

  def self.associated_with_component(component)
    all.select do |server|
      components_on_aspects = server.server_aspects.map do |aspect|
        aspect.installed_components
      end.flatten.map { |ic| ic.component }

      components_on_server = server.installed_components.map { |ic| ic.component }

      (components_on_aspects | components_on_server).include? component
    end
  end

  def self.id
    0
  end

  def self.per_page
    # for will paginate
    30
  end

  def available_environments
    Environment.active
  end

  def SUPPRESS_literal_property_value_for(property)
    property_values.find_by_property_id(property.id).try(:value) || property.default_value
  end

  def oldupdate_property_value_for(property, value)
    pv = property_values.find_or_initialize_by_property_id(property.id)
    pv.update_attributes :value => value if pv.value != value
  end

  def update_property_value_for(property, value)
    property.update_value_for_object(self, value)
  end

  def environment_names_for(user)
    @environments_names = environments_for(user).map(&:name).to_sentence
  end

  def environments_for(user)
    @envs = environments & user.accessible_environments
  end

  def app_names_for(user)
    apps_for(user).map(&:name).to_sentence
  end

  def apps_for(user)
    apps_related_to_server(user) & user.accessible_apps
  end

  def apps_related_to_server(user)
    related_app_objects = []
    environments_for(user).each { |env| related_app_objects << env.apps }
    related_app_objects.flatten.uniq
  end

  def deactivate!
    self.update_attribute(:active, false)

    # server being deactivated should loose association with appropriate steps
    Step.remove_servers_association! [self.id], :ignore_components
  end

  def environments_per_application_environment_apps_for(user)
    user_app_ids = user.apps.map(&:id)

    if new_record?
      available_environments.id_equals(environment_ids).by_app_env_apps(user_app_ids)
    else
      environments.select{|env| env.application_environments.detect{ |app_env| app_env.app_id.in?(user_app_ids) }.present?}
    end
  end

  private

  def validate_environment_removal( env )
    unless env.can_remove_server_association?( id )
      errors.add :base, I18n.t('environment.validations.server_referenced')
      raise ActiveRecord::RecordInvalid.new self
    end
  end

end
