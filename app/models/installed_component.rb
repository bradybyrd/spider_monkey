################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class InstalledComponent < ActiveRecord::Base
  include FilterExt
  
  concerned_with :import_app_installed_components

  # runs lookups for the child objects that may come in as bare names
  before_validation :find_application_environment, :find_application_component,
                    :find_properties_with_values, :find_server_group_name,
                    :find_server_names, :find_server_aspect_names, :find_server_aspect_group_names,
                    :toggle_server_association_type

  # if the validations all went well, we can update the properties
  after_save :update_properties_with_values

  after_find :preserve_current_server_ids
  after_save :update_steps_servers!

  # checks that any needs lookups succeeded
  validate :lookups_succeeded
  validates_presence_of :application_component_id, :application_environment_id
  validates_uniqueness_of :application_component_id, :scope => :application_environment_id

  # accessors for holding bare names that will trigger lookups and validations
  attr_accessor :app_name, :environment_name, :component_name,
                :application_environment_lookup_failed, :application_component_lookup_failed,
                :properties_with_values, :properties_with_values_sanitized, :properties_with_values_lookup_failed,
                :server_group_name, :server_group_name_lookup_failed,
                :server_names, :server_names_lookup_failed,
                :server_aspect_names, :server_aspect_names_lookup_failed,
                :server_aspect_group_names, :server_aspect_group_names_lookup_failed,
                :server_association_type,
                :previous_server_ids, :previous_server_aspect_ids

  belongs_to :application_component
  belongs_to :application_environment
  belongs_to :reference, :class_name => 'InstalledComponent'

  has_many :associated_current_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :include => :property, :conditions => { 'deleted_at' => nil, 'properties.active' => true }

  # This wrapper is same as the above association and is only used in REST Calls
  # FIXME: This should be removed as it is misleadingly named (suggests properties not values will be returned)
  # and is a duplicate of associated_current_property_values...
  has_many :find_properties, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :include => :property, :conditions => { 'deleted_at' => nil, 'properties.active' => true }

  has_many :associated_deleted_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NOT NULL'
  has_many :associated_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy
  accepts_nested_attributes_for :associated_property_values, :allow_destroy => true
  has_many :associated_temporary_property_values, :as => :original_value_holder, :class_name => 'TemporaryPropertyValue', :dependent => :destroy
  accepts_nested_attributes_for :associated_temporary_property_values, :allow_destroy => true

  has_many :steps

  has_many :version_tags

  belongs_to :server_group, :foreign_key => 'default_server_group_id'
  has_and_belongs_to_many :server_aspects, :join_table => 'icsas'
  has_and_belongs_to_many :servers
  has_and_belongs_to_many :server_aspect_groups, :join_table => 'icsags'

  ### RVJ: 27 Apr 2012 : RAILS_3_UPGRADE: Got rid of the finder SQL
  has_many :server_aspects_through_groups, :class_name => "ServerAspect", :through => :server_aspect_groups, :source => :server_aspects
  #:finder_sql =>
  #  'SELECT sa.* ' +
  #  'FROM server_aspects sa ' +
  #  'INNER JOIN icsags ON icsags.installed_component_id = #{id} ' +
  #  'INNER JOIN sagsas ON sagsas.server_aspect_group_id = icsags.server_aspect_group_id ' +
  #  'WHERE sa.id = sagsas.server_aspect_id'


  attr_accessible :application_environment_id, :application_component_id, :application_component,
                  :application_environment, :version, :server_ids, :server_aspect_group_ids, :default_server_group_id,
                  :server_aspect_ids, :reference, :app_name, :environment_name, :component_name,
                  :application_environment_lookup_failed, :application_component_lookup_failed,
                  :properties_with_values, :properties_with_values_lookup_failed,
                  :server_group_name, :server_group_name_lookup_failed,
                  :server_names, :server_names_lookup_failed,
                  :server_aspect_names, :server_aspect_names_lookup_failed,
                  :server_aspect_group_names, :server_aspect_group_names_lookup_failed,
                  :server_association_type, :reference_id

  validates :application_component, :presence => true
  validates :application_environment, :presence => true

  delegate :app, :app_id, :app_id=, :component, :component_id, :component_id=, :to => :application_component
  delegate :properties, :to => :component
  delegate :environment, :environment_id, :environment_id=, :to => :application_environment

  scope :in_given_environment, lambda { |environment_id| includes(:application_environment).where('application_environments.environment_id' => environment_id) }

  scope :for_app, lambda { |app_id|
    { :include => :application_component, :conditions => { 'application_components.app_id' => app_id } }
  }

  scope :for_component, lambda { |component_id|
    { :include => :application_component, :conditions => { 'application_components.component_id' => component_id } }
  }

  scope :for_environment_name, lambda { |environment_name|
    { :include => [:application_environment => :environment], :conditions => { 'environments.name' => environment_name } }
  }

  scope :for_app_name, lambda { |app_name|
    { :include => [:application_component => :app], :conditions => ['apps.name like ? OR apps.name like ?', app_name, "#{app_name}_|%"] }
  }

  scope :for_component_name, lambda { |component_name|
    { :include => [:application_component => :component], :conditions => { 'components.name' => component_name } }
  }

  scope :for_server_group_name, lambda { |server_group_name|
    { :include => :server_group, :conditions => { 'server_groups.name' => server_group_name } }
  }

  scope :preload_reference_objects, -> {
    includes([:reference, {application_component: :component}])
  }

  is_filtered cumulative_by: {app_name: :for_app_name,
                              app_id: :for_app,
                              component_name: :for_component_name,
                              component_id: :for_component,
                              environment_name: :for_environment_name,
                              environment_id: :in_given_environment,
                              server_group_name: :for_server_group_name},
              default_flag: :all

  # steps' servers should loose association when servers are being deassigned from installed_component
  def self.update_steps_servers(subject, ids = [], component_ids = [])
    case subject
    when :servers
      Step.remove_servers_association! ids, component_ids
    when :server_aspects
      Step.remove_server_aspects_association! ids, component_ids
    end

    return true

  rescue => e
    raise 'Could not remove servers from steps.' + e.message
  end

  def self.without_finding_server_ids
    InstalledComponent.skip_callback(:find, :after, :preserve_current_server_ids)
    result = yield
    InstalledComponent.set_callback(:find, :after, :preserve_current_server_ids)

    result
  end
 
  #after_save :add_server_to_steps, :unless => Proc.new{|ic| ic.servers.blank?}

  def steps_using_component
    Step.find_all_by_component_id(component.id, :include => :request,
    :conditions => {"requests.environment_id" => environment.id})
  end

  def add_server_to_steps
    steps_using_component.each do |step|
      servers.each do |s|
        step.servers << s unless step.server_ids.include?(s.id)
      end
    end
  end

  def clear_servers!
    self.server_aspect_ids_without_remove_other_servers = []
    self.server_ids_without_remove_other_servers = []
    self.server_aspect_group_ids_without_remove_other_servers = []
    self[:default_server_group_id] = nil
  end

  # FIXME: This should be handled with hooks since it does not cover
  # reverse cases
  def default_server_group_id=(new_id)
    clear_servers!
    self[:default_server_group_id] = new_id
  end

  def server_aspect_ids_with_remove_other_servers=(ids)
    clear_servers!
    self.server_aspect_ids_without_remove_other_servers = ids
  end
  alias_method_chain :server_aspect_ids=, :remove_other_servers

  def server_aspect_group_ids_with_remove_other_servers=(ids)
    clear_servers!
    self.server_aspect_group_ids_without_remove_other_servers = ids
  end
  alias_method_chain :server_aspect_group_ids=, :remove_other_servers

  def server_ids_with_remove_other_servers=(ids)
    clear_servers!
    self.server_ids_without_remove_other_servers = ids
  end
  alias_method_chain :server_ids=, :remove_other_servers

  def server_ids_from_servers_or_server_groups
    server_ids    = []

    if self.server_group
      # get assigned server ids to installed component throught server_group
      server_ids  = self.server_group.server_ids
    else
      # get assigned server ids to installed component
      server_ids  = self.server_ids
    end

    return server_ids.uniq
  end

  def server_aspect_ids_from_server_aspects_or_server_group_aspects
    server_aspect_ids = []

    if !self.server_aspects.empty?
      # server_aspects
      # get assigned server ids to installed component throught server_level
      server_aspect_ids = self.server_aspect_ids
    elsif !self.server_aspect_groups.empty?
      # server_aspect_groups
      # get assigned server ids to installed component throught server_level_groups
      self.server_aspect_groups.each do |server_aspect_group|
        server_aspect_ids = server_aspect_group.server_aspect_ids
      end
    end

    return server_aspect_ids.to_a.uniq
  end

  def name
    reference ? reference.path : component.name
  end

  def path
    "#{app.name}:#{environment.name}:#{component.name}"
  end

  def server_level
    server_associations.first.try(:server_level)
  end

  def should_modify_level?(server_level_id)
    server_associations.empty? || server_level_id.to_i == server_associations.first.server_level.id
  end

  def add_server_associations(server_level_id, association_ids_to_add)
    return unless should_modify_level? server_level_id
    return if association_ids_to_add.blank?

    new_ids = association_ids_to_add.map { |id| id.to_i } | server_association_ids
    if server_level_id.to_i.zero?
      self.server_ids = new_ids
    else
      self.server_aspect_ids = new_ids
    end
  end

  def remove_server_associations(server_level_id, association_ids_to_remove)
    return unless should_modify_level? server_level_id
    return if association_ids_to_remove.blank?

    new_ids = server_association_ids - association_ids_to_remove.map { |id| id.to_i }
    if server_level_id.to_i == 0
    self.server_ids = new_ids
    else
    self.server_aspect_ids = new_ids
    end
  end

  def server_associations(force_reload = false)
    return reference.server_associations if reference

    if servers.any?
      servers.active force_reload
    elsif default_server_group_id?
      ServerGroup.find(default_server_group_id).servers.active
    elsif server_aspects.any?
      server_aspects force_reload
    else
      server_aspects_through_groups force_reload
    end
  end

  def physical_server_associations
    return reference.server_associations if reference

    if servers.any?
      servers.active
    elsif default_server_group_id?
      ServerGroup.find(default_server_group_id).servers.active
    elsif server_aspects.any?
      #svr = []
      #server_aspects.each do |sa|  svr  = svr +  sa.servers end
      #svr
      []
    else
      #svr = []
      #server_aspects_through_groups.each do |sa|  svr  = svr +  sa.servers end
      #svr
      []
    end
  end

  def server_association_ids
    server_associations.map(&:id)
  end

  def server_association_ids(force_reload = false)
    server_associations(force_reload).map { |sa| sa.id }
  end

  def server_association_names
    server_associations.map { |sa| sa.name }
  end

  def id_for_property_values
    reference_id || id
  end

  def current_property_values
    reference ? reference.associated_current_property_values : associated_current_property_values
  end

  def deleted_property_values
    reference ? reference.associated_deleted_property_values : associated_deleted_property_values
  end

  def property_values
    reference ? reference.associated_property_values : associated_property_values
  end

  def last_deploy
    app_id = application_component.app_id
    env_id = application_environment.environment_id
    step = self.application_component.component.steps.first(
    :select => "steps.work_finished_at",
    :joins => [" INNER JOIN requests ON requests.id = steps.request_id " +
      " INNER JOIN apps_requests ON apps_requests.request_id = requests.id "],
    :conditions => ['steps.work_finished_at IS NOT NULL AND apps_requests.app_id = ? AND requests.environment_id = ?', app_id, env_id],
    :order => 'steps.work_finished_at DESC')
    return if step.nil?
    step.work_finished_at.default_format
  end

  def property_value_for(given_property, user = nil)
    self.current_property_values.first(:conditions => { :property_id => given_property.id })
  end

  def literal_property_value_for(given_property, user = nil)
    editable = user.can_see_property?(given_property) unless user.nil?
    if user.nil? || editable
      property = if current_property_values.find_by_property_id(given_property.id).try(:value).present?
        current_property_values.find_by_property_id(given_property.id).try(:value)
      else
        application_component.literal_property_value_for(given_property)
      end
    property
    else
      "&lt;private&gt;"
    end
  end

  def literal_property_value_for_by_s(given_property, date_of_change)
    current_property_values.upto_date(date_of_change).find_by_property_id(given_property.id).try(:value) || application_component.literal_property_value_for(given_property)
  end

  def update_property_value_for(property, value)
    if property.apps.include? app
      property.update_value_for(application_component, value)
    else
    property.update_value_for_installed_component(self, value)
    end
  end

  # Following method was added , becase default value of property of component is now available
  # across all the environments of application, so now application components will get updated value of property

  def update_property_value_for_app_comp
    app_comp_id = application_component.id
    new_property_value = current_property_values.map(&:value)
    property_val_objs = PropertyValue.values_for_app_comp(app_comp_id)
    property_val_objs.each do |property_val_obj|
      property_val_obj.update_attribute( "value", new_property_value.to_s )
    end
  end

  def self.find_by_app_comp_env(app, comp, env)
    ac_id = ApplicationComponent.select(:id).find_by_app_id_and_component_id(app,comp).try(:id)
    ae_id = ApplicationEnvironment.select(:id).find_by_app_id_and_environment_id(app,env).try(:id)
    InstalledComponent.find_by_application_component_id_and_application_environment_id(ac_id, ae_id) if ac_id && ae_id
  end

  def self.create_or_find_for_app_component(app_id, comp_id, env_id = nil)
    result = []
    app = App.active.find_by_id(app_id)
    unless app.nil?
      ac = app.application_components.find_by_component_id(comp_id)
      unless ac.nil?
        aes = [app.application_environments.find_by_environment_id(env_id)] if env_id
        aes = app.application_environments unless env_id
        aes.each do |ae|
          result << InstalledComponent.find_or_create_by_application_component_id_and_application_environment_id(ac.id,ae.id)
        end
      end
    end
    result
  end

  # save current server_ids and server_aspect_ids
  def preserve_current_server_ids
    @previous_server_ids        = self.server_ids_from_servers_or_server_groups
    @previous_server_aspect_ids = self.server_aspect_ids_from_server_aspects_or_server_group_aspects
  end

  def current_associated_property_values
    prop_values = []
    properties.each { |prop|
      prop_values << prop.value_for_ic_as_hash(self)
    }
    prop_values
  end

  def get_server_group_name
    caption = 'Servers'
    if server_group.present?
      caption = "Server Group: #{server_group.name}"
    elsif server_aspect_groups.present?
      caption = 'Server Level Group: '
      server_aspect_groups.each {|server_aspect_group| caption += "#{server_aspect_group.name} "}
    elsif server_level.present? && (server_level.is_a? ServerLevel)
      caption = "Server Level: #{server_level.name} "
    end
    caption
  end

  private

  # convenience finder (mostly for REST clients) that allows you to pass an app_name
  # and an environment name and have us locate the application environment
  def find_application_environment
    self.application_environment_lookup_failed = false
    unless self.app_name.blank? || self.environment_name.blank?
      my_application_environment = ApplicationEnvironment.by_application_and_environment_names(self.app_name, self.environment_name).first
      unless my_application_environment.blank?
        self.application_environment = my_application_environment
      else
        self.application_environment_lookup_failed = true
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  # convenience finder (mostly for REST clients) that allows you to pass an app_name
  # and a component_name and have us look up the correct application component
  def find_application_component
    self.application_component_lookup_failed = false
    unless self.app_name.blank? || self.component_name.blank?
      my_application_component = ApplicationComponent.by_application_and_component_names(self.app_name, self.component_name).try(:first)
      unless my_application_component.blank?
        self.application_component = my_application_component
      else
        self.application_component_lookup_failed = true
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  # convenience finder (mostly for REST clients) that allows you to pass property value pairs
  # and have the matching properties looked up and updated safely
  def find_properties_with_values
    # normalize the incoming to always be an array because multipe XML tag sets might produce an array
    self.properties_with_values = [self.properties_with_values].compact unless self.properties_with_values.is_a? Array
    self.properties_with_values_lookup_failed = false
    self.properties_with_values_sanitized = []
    if self.properties_with_values.present?
      # start stepping through the values
      self.properties_with_values.each do |pv|
        # in order to support XML, we support a verbose format with property_name and property value tags
        # so we need to figure out which allowed format we have
        if pv[:property_name].present? && pv[:property_value].present?
          property_name = pv[:property_name]
          p_value = pv[:property_value]
          # find the property
          my_property = self.properties.find_by_name(property_name.to_s)
          # if the property is found, change its value
          if my_property.blank?
            self.properties_with_values_lookup_failed = true
            self.errors.add(:properties_with_values, "contained references to properties could not be found. Did you confirm the property exists and the name is correct?")
          else
            self.properties_with_values_sanitized << { :property => my_property, :value => p_value }
          end
        else
          # otherwise we likely have the short form suitable for json and one work XML elements
          pv.each_pair do |p_name, p_value|
          # find the property
            my_property = self.properties.find_by_name(p_name.to_s)
            Rails.logger.info("-------my_property: " + my_property.inspect)
            # if the property is found, change its value
            if my_property.blank?
              self.properties_with_values_lookup_failed = true
              self.errors.add(:properties_with_values, "contained references to properties could not be found. Did you confirm the property exists and the name is correct?")
              break
            else
              self.properties_with_values_sanitized << { :property => my_property, :value => p_value }
            end
          end
         end
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  # property updates have to be done after the record is saved, so this is called by an
  # after save hook
  def update_properties_with_values
    # don't do anything if there was an error looking them up or no properties were passed
    unless self.properties_with_values_lookup_failed || self.properties_with_values_sanitized.blank?
      # looped through the passed pairs
      self.properties_with_values_sanitized.each do |my_property_row|
        my_property = my_property_row[:property]
        my_value = my_property_row[:value]
        # if the property is found, change its value
        unless my_property.blank?
          my_property.update_value_for_installed_component(self, my_value)
        end
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  # convenience finder (mostly for REST clients) that allows you to pass a server_group_name
  # and a component_name and have us look up the correct server group
  def find_server_group_name
    self.server_group_name_lookup_failed = false
    unless self.server_group_name.blank?
      my_server_group = ServerGroup.find_by_name(self.server_group_name)
      unless my_server_group.blank?
        self.server_group = my_server_group
        self.server_association_type = 'server_group'
        self.server_group_name = nil
      else
      self.server_group_name_lookup_failed = true
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  # convenience finder (mostly for REST clients) that allows you to pass a server_names
  # and a component_name and have us look up the correct server names
  def find_server_names
    self.server_names_lookup_failed = false
    unless self.server_names.blank?
      my_servers = Server.find_all_by_name(self.server_names)
      unless my_servers.blank? || my_servers.length != Array(self.server_names).length
        self.servers = my_servers
        self.server_association_type = 'server'
        self.server_names = nil
      else
      self.server_names_lookup_failed = true
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  # convenience finder (mostly for REST clients) that allows you to pass server aspect names
  # and a component_name and have us look up the correct server aspect names
  def find_server_aspect_names
    self.server_aspect_names_lookup_failed = false
    unless self.server_aspect_names.blank?
      my_server_aspects = ServerAspect.find_all_by_name(self.server_aspect_names)
      unless my_server_aspects.blank? || my_server_aspects.length != Array(self.server_aspect_names).length
        self.server_aspects = my_server_aspects
        self.server_association_type = 'server_aspect'
        self.server_aspect_names = nil
      else
      self.server_aspect_names_lookup_failed = true
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  # convenience finder (mostly for REST clients) that allows you to pass a server_aspect_group_names
  # and a component_name and have us look up the correct server aspect groups
  def find_server_aspect_group_names
    self.server_aspect_group_names_lookup_failed = false
    unless self.server_aspect_group_names.blank?
      my_server_aspect_groups = ServerAspectGroup.find_all_by_name(self.server_aspect_group_names)
      unless my_server_aspect_groups.blank? || my_server_aspect_groups.length != Array(self.server_aspect_group_names).length
        self.server_aspect_groups = my_server_aspect_groups
        self.server_association_type = 'server_aspect_group'
        self.server_aspect_group_names = nil
      else
      self.server_aspect_group_names_lookup_failed = true
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  # toggles the values between servers, server groups, and server aspects
  def toggle_server_association_type
    case self.server_association_type
    when 'server_group'
      self.servers.clear
      self.server_aspects.clear
      self.server_aspect_groups.clear
    when 'server'
      self[:default_server_group_id] = nil
      self.server_aspects.clear
      self.server_aspect_groups.clear
    when 'server_aspect'
      self[:default_server_group_id] = nil
      self.servers.clear
      self.server_aspect_groups.clear
    when 'server_aspect_group'
      self[:default_server_group_id] = nil
      self.servers.clear
      self.server_aspects.clear
    end

    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  def lookups_succeeded
    self.errors.add(:application_environment, "could not be found. Check that the application and environment are valid.") if self.application_environment_lookup_failed
    self.errors.add(:application_component, "could not be found. Check that the application and component are valid.") if self.application_component_lookup_failed
    self.errors.add(:properties_with_values, "could not be found. Check that the property and the values are valid for this component.") if self.properties_with_values_lookup_failed
    self.errors.add(:server_group_name, "could not be found. Check that the server group name is valid.") if self.server_group_name_lookup_failed
    self.errors.add(:server_names, "could not be found. Check that the server names are valid.") if self.server_names_lookup_failed
    self.errors.add(:server_aspect_names, "could not be found. Check that the server aspect names are valid.") if self.server_aspect_names_lookup_failed
    self.errors.add(:server_aspect_group_names, "could not be found. Check that the server aspect group names are valid.") if self.server_aspect_group_names_lookup_failed
  end

  # determine servers and server_aspects that were deassigned from installed_component
  # and update appropriate steps' servers
  def update_steps_servers!
    current_server_ids        = self.server_ids_from_servers_or_server_groups
    current_server_aspect_ids = self.server_aspect_ids_from_server_aspects_or_server_group_aspects
    component_ids             = [self.component_id]
    previous_server_ids       = @previous_server_ids || []
    previous_server_aspect_ids= @previous_server_aspect_ids || []

    subject, server_ids = :servers, previous_server_ids - current_server_ids if !previous_server_ids.empty?
    subject, server_ids = :server_aspects, previous_server_aspect_ids - current_server_aspect_ids if !previous_server_aspect_ids.empty?

    InstalledComponent.update_steps_servers subject, server_ids, component_ids
  end
end
