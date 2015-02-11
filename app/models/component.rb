################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Component < ActiveRecord::Base

  include SoftDelete
  include QueryHelper
  include FilterExt

  # TODO: RJ, Rails 3 : Log activities disabled until new plugin/gem is incorporated
  #log_activities

  has_many :application_components, :dependent => :destroy
  has_many :apps, :through => :application_components
  has_many :installed_components, :through => :application_components

  # FIXME: does this association still have meaning?  We use installed components to relate to steps, no?
  has_many :steps

  has_many :component_properties
  has_many :properties, through: :component_properties, order: 'component_properties.position'
  has_many :active_properties, through: :component_properties,
                               order: 'component_properties.position'
  accepts_nested_attributes_for :properties, allow_destroy: true

  validates :name,
    :presence => true,
    :length => {:maximum => 255},
    :uniqueness => {:case_sensitive => false }

  # FIXME: the concept of "not from rest" should be depricated and removed in later versions
  # as the code should work equally well in both modes with simple tests, not explicit flag setting.
  attr_accessor :not_from_rest, :current_value,
                :app_name, :application_lookup_failed,
                :property_name, :property_lookup_failed

  validate :lookups_succeeded

  before_validation :find_application, :find_property


  normalize_attributes :name

  attr_accessible :name, :not_from_rest, :app_name, :current_value, :application_lookup_failed, :property_name, :property_lookup_failed, :active

  scope :accessible_components_to_user, lambda { |user_id|
    joins(:application_components => { :app => :assigned_apps }).where("assigned_apps.user_id" => user_id)
  }

  # FIXME: This assumed the user wants to search down to installed components, not just application_components.  Is that correct?
  # Better, I think, to use installed components for application_environment bound filtering.
  scope :by_application_name, lambda { |app_name|
    {
      :select => Component.column_names.collect{|c| c == "id" ? "DISTINCT(components.#{c})" : "components.#{c}" }.join(", "),
      :joins => [" INNER JOIN application_components ON application_components.component_id = components.id "+
          " INNER JOIN installed_components ON installed_components.application_component_id = application_components.id "+
          " INNER JOIN apps ON apps.id = application_components.app_id "],
      :conditions => {'apps.name' => app_name }
    }
  }

  # FIXME: we promised BNP to allow them to use a custom name for applications (identifier_|_description)
  # while this is not ideal (a tag column might have been offered instead), we might have to support this
  # so the following finder will add this capability to a named scope that otherwise duplicates the above
  scope :for_app_name, lambda { |app_name|
    { :include => :apps, :conditions => ['apps.name like ? OR apps.name like ?', app_name, "#{app_name}_|%"] }
  }

  #Can replace above after testing
  #scope :by_application_name,lambda { |app_name|  select('distinct components.*').joins(:application_components => :installed_components).joins(:application_components => :app).where('apps.name' => app_name) }

  scope :by_environment_name, lambda { |environment_name, my_app_name|
    {
      :conditions => {'environments.name' => environment_name, 'apps.name' => my_app_name},
      :joins => [ :apps, { :installed_components => [{ :application_environment => :environment }] } ]
    }
  }

  scope :for_name, lambda { |component_name|
    { :conditions => ['UPPER(components.name) like ?', component_name.upcase] }
  }

  scope :for_property_name, lambda { |property_name|
    { :include => :properties, :conditions => ['properties.name like ?', property_name] }
  }

  #Can replace above after testing
  #scope :by_environment_name, lambda { |environment_name, app_name|  joins(:apps).joins(:installed_components =>{ :application_environment => :environment }).where('environments.name' => environment_name, 'apps.name' => app_name)}

  scope :accessible_components_for_app, lambda { |app_id| where("assigned_apps.app_id" => app_id) }


  scope :installed_components_on_app, joins(:application_components => :installed_components)

  scope :accessible_components_to_admin, lambda { |app_id|
    joins(apps: :assigned_apps).where(assigned_apps: {app_id: app_id})
  }

  scope :components_for_apps, lambda {|app_ids|
    {
      :select => ["DISTINCT components.*"],
      :joins => ["INNER JOIN application_components ON application_components.component_id = components.id"],
      :conditions => {"application_components.app_id" => app_ids},
      :order => ["components.name ASC"]
    }
  }
  #Can replace above after testing
  #scope :accessible_components_to_admin, lambda { |app_id|  joins(:application_components => {:app => :assigned_apps}).joins(:installed_components).on(installed_components[:application_component_id]).eq(application_components[:id]).where("assigned_apps.user_id" => user_id) }


  scope :via_team, where("team_id IS NOT NULL")

  def deactivate!
    if destroyable?
      self.update_attribute(:active, false)
      return true
    else
      return false
    end
  end

  def activate!
    self.update_attribute(:active, true)
    return true
  end

  is_filtered cumulative_by: {app_name: :for_app_name, name: :for_name,  property_name: :for_property_name},
              boolean_flags: {default: :active, opposite: :inactive}

  class << self

    def import_app_request(xml_hash)
      if(xml_hash["component"])
        componentname =  xml_hash["component"]["name"]
        component = Component.find_by_name componentname
        component ? component.id : nil
      end
    end

    def installed_on_environment(environment)
      application_environment_ids =
        ApplicationEnvironment.all(:select => 'application_environments.id',
        :conditions => { :environment_id => environment.id }).map { |ae| ae.id }

      application_component_ids =
        InstalledComponent.all(:select => 'installed_components.application_component_id',
        :conditions => { :application_environment_id => application_environment_ids }).map { |ic| ic.application_component_id }

      component_ids =
        ApplicationComponent.all(:select => 'application_components.component_id',
        :conditions => { :id => application_component_ids }).map { |ac| ac.component_id }

      Component.find_all_by_id(component_ids)
    end

    def with_enumerable_properties(options = {})
      all(options.merge(:include => :properties)).select { |c| c.properties.any? { |p| p.multiple_default_values? } }
    end
  end

  # convenience finder (mostly for REST clients)
  def find_by_name_resolver
    return unless not_from_rest.nil?
    unless self.find_properties.blank?
      self.find_properties.each {|key, value|
        initialize_attr_accessors if self.find_property.nil? || self.current_value.nil?
        if value.is_a?(Hash)
          self.find_property = value["find_property"] if value.has_key?("find_property")
          self.current_value[value["find_property"]] = value["current_value"] if self.find_property && value.has_key?("current_value")
        elsif value.is_a?(Array)
          value.each do |hsh|
            self.find_property << hsh["find_property"] if hsh.has_key?("find_property")
            self.current_value[hsh["find_property"]] = hsh["current_value"] if self.find_property && hsh.has_key?("current_value")
          end
        end
      }
    end
    self.application_failed = find_application.nil?
    self.environment_failed = find_environment.nil?
    logger.info "SS__ ComponentResolver: #{self.inspect}"
    # from the validation loop
    return true
  end

  def destroyable?
    # overridden from SoftDelete since properties are associated automatically
    #puts "Component :: destroyable? :: application_components = #{application_components.inspect}"
    self.application_components.empty?
  end

  def granter_type(user)
    if installed_components.present? && has_installed_components_by_apps?(user)
      :environment
    else
      :application
    end
  end

  def has_installed_components_by_apps?(user)
    app_ids = user.apps.map(&:id)
    app_comp_ids = application_components.select{|app_comp| app_comp.app_id.in?(app_ids)}.map(&:id)
    (installed_components.map(&:application_component_id) & app_comp_ids).present?
  end

  private

  # convenience finder (mostly for REST clients) that allows you to pass an app_name
  # and have us look up the correct application component
  def find_application
    unless self.app_name.blank?
      my_apps = []
      # in the case of an array, the new finder will not work
      Array(self.app_name).each do |individual_name|
        new_apps = App.active.by_short_or_long_name(individual_name)
        logger.info "new_apps" + new_apps.inspect
        my_apps += new_apps unless new_apps.blank?
        logger.info "my_apps" + my_apps.inspect
      end
      unless my_apps.blank? || my_apps.length != Array(self.app_name).length
        self.apps << my_apps - self.apps
      else
        self.application_lookup_failed = true
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  # convenience finder (mostly for REST clients) that allows you to pass a property_name
  # and have us look up the correct property and assign it to the component
  def find_property
    unless self.property_name.blank?
      my_properties = Property.active.find_all_by_name(self.property_name)
      unless my_properties.blank? || my_properties.length != Array(self.property_name).length
        self.properties = my_properties
      else
        self.property_lookup_failed = true
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  # a validation test to determine if the special finder lookups succeeded
  def lookups_succeeded
    self.errors.add(:app_name, " was not found in active applications.") if self.application_lookup_failed
    self.errors.add(:property_name, " was not found in active properties.") if self.property_lookup_failed
  end

end
