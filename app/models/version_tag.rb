################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'sortable_model'

class VersionTag < ActiveRecord::Base
  include ArchivableModelHelpers
  include FilterExt

  normalize_attributes :name

  belongs_to :app, :foreign_key => 'app_id'
  belongs_to :application_environment, :foreign_key => 'app_env_id'
  belongs_to :installed_component, :foreign_key => 'installed_component_id'
  has_many :steps
  # necessary for sorting by component name
  has_one :application_component, :through => :installed_component
  has_one :component, :through => :application_component

  has_many :linked_items, :as => :source_holder, :dependent => :destroy   # This version tag object may have many owners

  has_many :linked_version_tags, :through => :linked_items, :as => :target_holder,
    :source => :target_holder, :source_type => 'VersionTag'

  has_many :properties_values, as: :value_holder, class_name: 'PropertyValue', dependent: :destroy, order: 'name',
           include: :property, conditions:  { 'deleted_at' => nil, 'properties.active' => true }

  validates :name,
            :presence => true,
            :length => { :maximum => 100, :allow_nil => true}

  #CHCKME:if this validation can be done be done the rails3 way?
  validates_uniqueness_of :name, :scope =>:installed_component_id, :if => :installed_component_id,:message =>'of the Version Tag is not unique for the given Component'
  validates_uniqueness_of :name, :scope => :app_env_id, :unless => :installed_component_id,:message =>'of the Version Tag is not unique for the given Application and Environment.'


  # FIXME - standardive as app_name
  attr_accessor :not_from_rest,:find_application, :find_environment, :find_component, :application_failed, :component_failed, :environment_failed, :component, :environment

  validate :lookups_succeeded

  validates :app,
            :presence => true
  validates :application_environment,
            :presence => {:unless => :installed_component}
  validates :artifact_url,
            :length => { :maximum => 250}

  #after_validation :version_completion



  before_validation :find_by_name_resolver

  attr_accessible :name, :artifact_url, :app_id, :not_from_rest, :installed_component_id,:find_environment, :find_component, :find_application, :app_env_id

  sortable_model

  can_sort_by :id, lambda{|asc| order("version_tags.id #{asc}")}
  can_sort_by :name, lambda{|asc| order("lower(version_tags.name) #{asc}")}
  can_sort_by :app, lambda{|asc| includes(:app).order("lower(apps.name) #{asc}")}
  can_sort_by :component, lambda{|asc| includes(:component).order("lower(components.name) #{asc}")}

  scope :desc_name_order,order('lower(name) desc')
  scope :name_order, order('lower(version_tags.name)')
  scope :sorted, order('lower(name)')

  scope :for_installed_component, lambda { |installed_comp|
     where('installed_component_id IN (select id from installed_components where application_component_id = ?)',
       installed_comp.application_component_id)
  }

  scope :by_name, lambda { |name| where(:name => name) }

  scope :by_application_name, lambda { |app_name| {
              :conditions => ['apps.name like ? OR apps.name like ?', app_name, "#{app_name}_|%"],
              :joins => [:app]
  }}

  scope :by_component_name, lambda { |component_name|
              where("installed_component_id IN (select installed_components.id from installed_components
                inner join application_components on installed_components.application_component_id = application_components.id
                inner join components on application_components.component_id = components.id where components.name like ?)", component_name)
  }

  scope :by_environment_name, lambda { |environment_name|
              where("installed_component_id IN (select installed_components.id from installed_components
                inner join application_environments on installed_components.application_environment_id = application_environments.id
                inner join environments on application_environments.environment_id = environments.id where environments.name like ?)", environment_name)
  }

  scope :for_application_environment, lambda {|environment_name|
    where("app_env_id IN (select application_environments.id from application_environments INNER JOIN environments on
                application_environments.environment_id = environments.id where environments.name = ?)", environment_name)
  }

  scope :application_versions, where("app_env_id is not NULL and installed_component_id is NULL")



  # convenience finder (mostly for REST clients) that allows you to pass a plan_template_name
  # and have us look up the correct plan template for you
  def find_by_name_resolver
    return  if self.app_id && not_from_rest

    unless self.find_application.blank?
      self.app = App.active.find_by_name(self.find_application)
      self.app = App.active.find(:first, :conditions => "name like '#{self.find_application}_|%'") if self.app.nil?
      self.application_failed = self.app.nil?
    end
    unless self.app.nil? || self.find_environment.blank?
      self.environment = self.app.environments.find_by_name(self.find_environment)
      self.environment_failed = self.environment.nil?
    end
    unless self.app.nil?
      ics = get_installed_component unless self.find_component.blank?
      self.component_failed = self.component.nil?
    end

    # be sure the call back returns true or else the call will fail with no error message
    logger.info "SS__ VersionResolver: #{self.inspect}"
    # from the validation loop
    return true
  end

  def get_installed_component
    #return unless self.installed_component_id.nil?
    logger.info "SS__ Attrs: App: #{self.find_application}, comp: #{self.component.try(:name)}, env: #{self.environment.try(:name)}"
    self.component = self.app.components.find_or_create_by_name(self.find_component)
    self.errors.add(:base, "VersionTag creation failed - no component") if self.component.nil?
    ics = InstalledComponent.create_or_find_for_app_component(self.app.id, self.component.id, self.environment.try(:id))
    self.installed_component = ics[0]
    ics
  end

  def update_environments
    # FIXME - BJB - better to return all version_tags created in xml - these don't get returned
    unless self.installed_component.nil?
      return unless self.find_environment.nil?
      version_tag_fields = {
        :name => self.name, :app_id => self.app.id, :artifact_url => self.artifact_url, :active => true
      }
      self.installed_component.application_component.installed_components.each_with_index do |ic, idx|
        if ic.id != self.installed_component_id
          # Create for all environments
          logger.info "SS__ Creating for env: #{ic.environment.name}"
          version_tag_fields[:installed_component_id] = ic.id
          ver = VersionTag.create(version_tag_fields)
          ver = ver.save(:validate => false)
          self.errors.add(:base, "VersionTag creation failed for Installed Component: #{ic.id}") if ver.nil?
        end
      end
    end
  end

  def lookups_succeeded
    self.errors.add(:find_application, " was not found in active applications.") if self.application_failed
    self.errors.add(:find_component, " was not found in active components.") if self.component_failed
    self.errors.add(:find_environment, " was not found in active environments.") if self.environment_failed
  end

  is_filtered cumulative_by: {name: :by_name,
                              app_name: :by_application_name,
                              component_name: :by_component_name,
                              environment_name: :by_environment_name},
              boolean_flags: {default: :unarchived, opposite: :archived}

  def application_name
    app.try(:name)
  end

  def component_name
    installed_component.try(:component).try(:name)
  end

  def environment_name
    return '-none-' if application_environment.nil? && installed_component.nil?
    if installed_component.nil?
      application_environment.environment.try(:name)
    else
      installed_component.try(:environment).try(:name)
    end
  end

  def assigned_properties_hashes
    properties_values.collect{|property_value| {:value => property_value.value, :name => property_value.property.name}}
  end

  def can_be_archived?
    #Sourabh:These are the only conditions used for archival now as self relation of version tag is not  getting used currently.
    (count_of_existing_requests_through_step == 0)  && (count_of_request_templates_through_steps == 0) && (count_of_procedures_through_steps ==0)
  end

  def update_from_params(hash, update_env = false)
    success = false
    ActiveRecord::Base.transaction do
      hash[:properties].each do |property_hash|
        property = Property.by_name(property_hash[:name]).first
        unless property
          property = Property.new(:name => property_hash[:name])
          property.save
        end
        if self.id
          property.update_value_for_object(self, property_hash[:value])
          self.properties_values.reload
        else
          property_value = PropertyValue.new(:value => property_hash[:value])
          property_value.property_id = property.id
          property_value.value_holder = self
          properties_values << property_value
        end
      end if hash[:properties]
      hash.delete(:properties)
      success = update_attributes(hash)
      raise ActiveRecord::Rollback unless success
      update_environments if success  && update_env
    end
    success
  end

end
