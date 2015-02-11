################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class Property < ActiveRecord::Base
  include SoftDelete
  include FilterExt
  attr_accessible :active, :created_at, :default_value, :is_private, :name, :updated_at, :property_values_with_holders

  paginate_alphabetically :by => :name

  has_many :current_property_values, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NULL'
  has_many :deleted_property_values, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NOT NULL'
  has_many :current_temporary_property_values, :class_name => 'TemporaryPropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NULL'
  has_many :deleted_temporary_property_values, :class_name => 'TemporaryPropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NOT NULL'
  has_many :property_holder_values, :class_name => 'PropertyValue', :as => :value_holder
  has_many :property_values, :dependent => :destroy
  has_many :script_argument_to_property_maps

  has_many :property_work_tasks, :dependent => :destroy
  has_many :work_tasks, :through => :property_work_tasks

  has_many :component_properties, :dependent => :destroy
  has_many :components, :through => :component_properties

  has_many :server_level_properties, :dependent => :destroy
  has_many :server_levels, :through => :server_level_properties

  has_many :package_properties, :dependent => :destroy
  has_many :packages, :through => :package_properties

  has_many :version_tags, :through => :current_property_values, :source => :value_holder, :source_type => 'VersionTag'

  has_and_belongs_to_many :servers
  has_and_belongs_to_many :apps

  attr_accessor :old_app_ids, :old_server_ids, :property_values_with_holders

  validates :name, :presence => true
  validates :name, :uniqueness => { :case_sensitive => false }
  validate :validate_property_values_with_holders   # before validation hook for special setter property

  before_save :destroy_values_if_component_changes
  after_save :update_work_tasks, :update_property_values, :update_script_argument_to_property_maps,
    :remove_property_value_references

  after_commit :set_property_values_with_holders

  attr_accessible :name, :default_value, :is_private, :server_ids, :package_ids, :component_ids, :execution_task_ids,
                  :creation_task_ids,:server_level_ids, :app_ids, :work_task_ids, :version_tag_ids

  scope :vary_by_environment_for, lambda { |app| where('properties.id NOT IN (?)', app.property_ids << 0) }
  scope :static_for, lambda { |app| where('properties.id IN (?)', app.property_ids) }
  scope :sorted, order('properties.name')
  scope :property_not_present, lambda{ |component_properties_id| where("properties.id NOT IN (?)", component_properties_id) }
  scope :filter_by_name, lambda { |filter_value| where("LOWER(properties.name) like ?", filter_value.downcase) }
  scope :by_name, lambda { |filter_value| where("LOWER(properties.name) = ?", filter_value.downcase) }
  scope :filter_by_current_value, lambda { |filter_value| includes(:current_property_values).where("LOWER(property_values.value) like ?", filter_value.downcase) }
  scope :filter_by_deleted_value, lambda { |filter_value| includes(:deleted_property_values).where("LOWER(property_values.value) like ?", filter_value.downcase) }
  scope :filter_by_app_name, lambda { |filter_value| includes(:apps).where("LOWER(apps.name) like ?", filter_value.downcase) }
  scope :filter_by_server_name, lambda { |filter_value| includes(:servers).where("LOWER(servers.name) like ?", filter_value.downcase) }
  scope :filter_by_component_name, lambda { |filter_value| includes(:components).where("LOWER(components.name) like ?", filter_value.downcase) }
  scope :filter_by_package_name, lambda { |filter_value| includes(:packages).where("LOWER(packages.name) like ?", filter_value.downcase) }
  scope :filter_by_server_level_name, lambda { |filter_value| includes(:server_levels).where("LOWER(server_levels.name) like ?", filter_value.downcase) }
  scope :filter_by_work_task_name, lambda { |filter_value| includes(:work_tasks).where("LOWER(work_tasks.name) like ?", filter_value.downcase) }

  # may be filtered through REST
  is_filtered cumulative: [:name, :app_name, :component_name, :package_name, :server_name, :server_level_name, :work_task_name,
                           :current_value, :deleted_value],
              boolean_flags: {default: :active, opposite: :inactive}

  def component_ids_with_destroy_unused_values=(new_components_ids)
    @removed_component_ids = component_ids - new_components_ids.collect {|i| i.to_i}
    self.component_ids_without_destroy_unused_values = new_components_ids
  end
  alias_method_chain :component_ids=, :destroy_unused_values

  def package_ids_with_destroy_unused_values=(new_packages_ids)
    new_packages_ids ||= []
    @removed_package_ids = package_ids - new_packages_ids.map(&:to_i)
    self.package_ids_without_destroy_unused_values = new_packages_ids
  end
  alias_method_chain :package_ids=, :destroy_unused_values

  def self.per_page
    # for will paginate
    30
  end

  class << self

    def create_new_instance(properties, component_ids)
      new_properties = {}
      properties.each do |name, value|
        new_properties[name.split("_").last] = Property.new(:name => value, :component_ids => component_ids)
      end
      new_properties
    end

    def validate_all(properties)
      validated_properties = []
      properties.values.each do |property|
        validated_properties << property  unless property.valid?
      end
      validated_properties
    end

    def validation_errors_of(properties)
      dummy_property = Property.new # dummy object used to feed error messages of invalid properties
      properties.each do |property|
        unless property.valid?
          property.errors.full_messages.each do |error_message|
            dummy_property.errors[:base] << error_message
          end
        end
      end
      dummy_property.errors.full_messages
    end

    def save_all(properties, args={})
      properties.each_pair { |property_number, property|
        property.save
        args[:application_component].application_environments.each do |app_env|
          installed_component = app_env.installed_component_for(args[:application_component].component)
          if args[:properties]["property_values_#{app_env.id}_#{property_number}"].present?
            property.update_value_for_installed_component(installed_component,
                args[:properties]["property_values_#{app_env.id}_#{property_number}"])
          end
        end
      }
    end

  end

  def multiple_default_values?
    false #(self[:default_value] || '').include?(',')
  end

  def default_values
    (self[:default_value] || '').split(/\s*,\s*/, -1).sort { |val1, val2| val1.downcase <=> val2.downcase }
  end

  def suppress_default_value
    # Do not want the multi-value choice
    multiple_default_values? ? default_values.first : self.default_value
  end

  def static_for?(app)
    apps.include? app
  end

  def execution_task_ids=(new_execution_task_ids)
    @new_execution_task_ids = new_execution_task_ids
  end

  def creation_task_ids=(new_creation_task_ids)
    @new_creation_task_ids = new_creation_task_ids
  end

  def execution_task_ids
    @execution_task_ids ||= property_work_tasks.on_execution.map { |pt| pt.work_task_id }
  end

  def creation_task_ids
    @creation_task_ids ||= property_work_tasks.on_creation.map { |pt| pt.work_task_id }
  end

  def entry_during_step_execution_on_task?(work_task)
    execution_task_ids.empty? || work_task && execution_task_ids.include?(work_task.id)
  end

  def entry_during_step_creation_on_work_task?(work_task)
    creation_task_ids.empty? || work_task && creation_task_ids.include?(work_task.id)
  end

  # Modified to fix the Bug in Properties view
  def property_value_for_date_and_installed_component_id(date_of_change, installed_component)
    date_of_change = date_of_change.utc
    value = installed_component.literal_property_value_for_by_s(self, date_of_change)
  end

  def value_changed_at_date_for_installed_component_id?(date_of_change, installed_component_id)
    date_of_change = date_of_change.utc
    property_values.count(:conditions => { :created_at => date_of_change, :value_holder_id => installed_component_id, :value_holder_type => "InstalledComponent" }) > 0
  end

  def value_for_installed_component(installed_component)
    installed_component.current_property_values.find_by_property_id(id)
  end

  def value_for_ic_as_hash(installed_component)
    ic_value = value_for_installed_component(installed_component)
    if ic_value.present?
      { id: ic_value.id, value: ic_value.value, name: name }
    else
      { id: 'default_value', value: default_value, name: name }
    end
  end

  def value_for_package_instance(package_instance)
    package_instance.current_property_values.find_by_property_id(id)
  end

  def value_for_reference(reference)
    reference.property_values.find_by_property_id(id)
  end

  def value_for_instance_reference(instance_reference)
    instance_reference.current_property_values.find_by_property_id(id)
  end

  def value_for_application_package(application_package)
    application_package.current_property_values.find_by_property_id(id)
  end

  def value_for_application_component(application_component)
    application_component.current_property_values.find_by_property_id(id)
  end

  def value_for_request(request)
    request.current_property_values.find_by_property_id(id)
  end

  def value_for_package_instance(package_instance)
    package_instance.current_property_values.find_by_property_id(id)
  end

  def value_for_server(server)
    server.current_property_values.find_by_property_id(id)
  end

  def value_for_server_aspect(server_aspect)
    server_aspect.current_property_values.find_by_property_id(id)
  end

  def value_for_server_level(server_level)
    server_level.current_property_values.find_by_property_id(id)
  end

  def value_for_version_tag(version_tag)
    version_tag.properties_values.find_by_property_id(id)
  end

  def value_for_property
    property_holder_values.find_by_deleted_at(nil)
  end

  def value_for_step(step)
    property_value = value_for_request(step.request)
    property_value = value_for_installed_component(step.installed_component) if property_value.nil?
    property_value = value_for_application_component(step.installed_component.application_component) if property_value.nil?
    property_value = value_for_property if property_value.nil?
  end

  def update_value_for_object(obj_item, given_value, locked=false)
    property_value = case obj_item.class.to_s
    when "Server"
      value_for_server(obj_item)
    when "ServerAspect"
      value_for_server_aspect(obj_item)
    when "ServerLevel"
      value_for_server_level(obj_item)
    when "Request"
      value_for_request(obj_item)
    when "ApplicationComponent"
      value_for_application_component(obj_item)
    when "InstalledComponent"
      value_for_installed_component(obj_item)
    when "PackageInstance"
      value_for_package_instance(obj_item)
    when "Reference"
      value_for_reference(obj_item)
    when "InstanceReference"
      value_for_instance_reference(obj_item)
    when "ApplicationPackage"
      value_for_application_package(obj_item)
    when "VersionTag"
      value_for_version_tag(obj_item)
    else
      value_for_property
    end
    current_value = property_value.nil? ? default_value : property_value.value
    #logger.info "SS__ UpdateForObject: #{obj_item.class.to_s}, #{obj_item.name}: Prop: #{name} - curval: #{current_value}, newval: #{given_value}"

    # locked - param from UI, if it is given we rewrite values
    if current_value != given_value || locked
      changed_time = Time.now
      logger.info "SS__ Prop: Update: #{given_value} Dumping: #{property_value.nil? ? "Nil" : property_value.value_holder_type}: #{property_value.nil? ? "Nil" : property_value.inspect}"
      property_value.update_attribute :deleted_at, changed_time if property_value
      if given_value.present?
        property_values.create!(:value_holder_id => obj_item.is_a?(InstalledComponent) ? obj_item.id_for_property_values : obj_item.id,
                                :value_holder_type => obj_item.class.to_s,
                                :locked => locked,
                                :created_at => changed_time, :value => given_value)
      end
    end
  end

  def update_value_for_installed_component(installed_component, given_value, locked=false)
    update_value_for_object(installed_component, given_value, locked)
  end

  def update_value_for_package_instance(package_instance, given_value, locked=false)
    update_value_for_object(package_instance, given_value, locked)
  end

  def update_value_for_reference(reference, given_value, locked=false)
    update_value_for_object(reference, given_value, locked)
  end

  def update_value_for_instance_reference(instance_reference, given_value, locked=false)
    update_value_for_object(instance_reference, given_value, locked)
  end


  def remove_property_for_installed_component(installed_component, app_comp)
    changed_time = Time.now
    app_comp.application_environments.each do |app_env|
      installed_component = app_env.installed_component_for(app_comp.component)
      property_values.find_all_by_value_holder_id_and_value_holder_type(installed_component.id,"InstalledComponent").collect{|prop_val| prop_val.update_attribute :deleted_at, changed_time}
    end
    comp_property = ComponentProperty.find_by_component_id_and_property_id(installed_component.component.id, id)
    comp_property.destroy if comp_property
  end

  def locked_for_installed_component?(app_comp)
    if app_comp.is_a?(ApplicationComponent)
      self.property_values.where(value_holder_type: "InstalledComponent", value_holder_id: app_comp.installed_components.pluck(:id), deleted_at: nil, locked: true).any?
    elsif app_comp.is_a?(InstalledComponent)
      self.property_values.where(value_holder_type: "InstalledComponent", value_holder_id: app_comp.id, deleted_at: nil, locked: true).any?
    else
      false
    end
  end

  def value_for(value_holder)
    value_holder.current_property_values.find_by_property_id(id)
  end

  def literal_value_for(value_holder)
    value_for(value_holder).try(:value) || default_value
  end

  def literal_display_value_for(value_holder)
    cur_value = literal_value_for(value_holder)
    is_private ? "-private-" : cur_value
  end

  def update_value_for(value_holder, new_value)

    value_obj = if value_holder.class.to_s == "InstalledComponent"
      value_holder.associated_property_values.find_by_property_id(id)
    else
      value_for value_holder
    end
    if value_obj.nil?
      value_obj = self.property_values.build
      value_obj.value_holder = value_holder
    end
    value_obj.value = new_value
    value_obj.save!
  end

  def archive_server_property_values!(deleted_server_ids)
    current_property_values.all(:conditions => {:value_holder_type => 'Server', :value_holder_id => deleted_server_ids}).collect{|pv|
      pv.update_attribute(:deleted_at, Time.now)
    }
  end

  def find_component_property(component_id)
    component_properties.by_property_and_component(id, component_id).first
  end

  def private?
    is_private
  end

  private

  def update_script_argument_to_property_maps
    unless @removed_component_ids.blank?
      satpms = ScriptArgumentToPropertyMap.property_id_equals(self.id).for_components.with_components(@removed_component_ids)
      satpms.destroy_all
    end
  end

  def update_property_values
    # Piyush 11-06-2010
    # When property is updated from MetaData > Properties
    # referenced property_values should be also updated
    # if this is not done then Capistrano and Bladelogic scripts still refer to old values of property

    # CHKME,Manish,2012-01-04, ambiguous conflict so kept old change just in case needed.
    # Piyush -  06-11-2010
    #pv = property_values.find_or_initialize_by_value_holder_type("Property")
    #pv.value_holder_id = self.id
    #pv.value = default_value
    #pv.created_at = Time.now
    #pv.save(false)
    #unless property_values.blank?
    #  # BJB 11--23-11 this overwrites all server values
    #  #property_values.value_holder_type_does_not_equal("InstalledComponent").update_all("value = '#{default_value}'")
    #### end of conflict.

    # Piyush 11-30-2011
    new_value = property_holder_values.create(:property_id => id, :value => default_value)
    property_holder_values.find_all_by_deleted_at(nil).each do |pv|
      pv.update_attribute(:deleted_at, Time.now) unless pv.id == new_value.id
    end
  end

  def destroy_values_if_component_changes
    if @removed_component_ids
      @removed_component_ids.each do |component_id|
        component = Component.find(component_id)
        values_to_destroy = property_values.all(:conditions => { :value_holder_id => component.installed_component_ids, :value_holder_type => "InstalledComponent" })
        values_to_destroy.each { |val| val.destroy }
      end
    end
  end

  def update_work_tasks
    property_work_tasks.clear

    if @new_execution_task_ids
      @new_execution_task_ids.each do |work_task_id|
        property_work_tasks.create(:work_task_id => work_task_id, :entry_during_step_execution => true)
      end
    end

    if @new_creation_task_ids
      @new_creation_task_ids.each do |work_task_id|
        pt = property_work_tasks.find_or_create_by_work_task_id(work_task_id)
        pt.entry_during_step_creation = true
        pt.save
      end
    end

    reload
  end

  def remove_property_value_references
    return if old_app_ids.nil?
    old_property_app_ids = old_app_ids
    deleted_property_app_ids =  old_property_app_ids - self.apps.map(&:id)
    deleted_property_apps = App.find(deleted_property_app_ids) if deleted_property_app_ids.present?
    deleted_property_apps.each do |app|
      value_holder_id = app.application_component_ids
      values_to_destroy = property_values.all(:conditions => { :value_holder_id => value_holder_id })
      values_to_destroy.each { |val| val.destroy }
    end if deleted_property_apps.present?
  end

  def validate_property_values_with_holders
    success = true
    self.property_values_with_holders = [self.property_values_with_holders] unless property_values_with_holders.is_a? Array
    if self.property_values_with_holders.present?
      # make sure the hash is has all the required keys
      invalid_pvs = self.property_values_with_holders.reject { |p| p[:value].nil? || p[:value_holder_type].blank? || p[:value_holder_id].blank? }
      if invalid_pvs.present?
        # make sure the holders are all valid
        valid_pvs = self.property_values_with_holders.select { |p| %w(Property Server ServerAspect ServerLevel ApplicationComponent InstalledComponent VersionTag).include?(p[:value_holder_type]) }
        count_of_invalid = self.property_values_with_holders.length - valid_pvs.length
        if count_of_invalid == 0
          # finally lets find each of the objects to be sure
          bad_ids = []
          property_values_with_holders.each do |pv|
            # set this to nil if it is not a valid class
            klass = pv[:value_holder_type].classify.safe_constantize
            if klass.present?
            value_object = klass.find_by_id(pv[:value_holder_id].to_i) if klass.present? && pv[:value_holder_id].to_i > 0
              if value_object.present?
              # store the object in the hash to use for the setter function after commit
              pv[:value_holder_object] = value_object
            else
              bad_ids << pv[:value_holder_id]
            end
            else
              self.errors.add(:property_values_with_holders, "contained an invalid value holder: #{ pv[:value_holder_type] }")
              # the class was not found
              success = false
            end
          end
          if bad_ids.present?
            self.errors.add(:property_values_with_holders, "contained value holder id[s] that could not be found: #{ bad_ids.to_sentence }")
            success = false
          else
            # everything checks out!
          end
        else
          self.errors.add(:property_values_with_holders, "contained #{count_of_invalid} object[s] with invalid property value holder types. Valid types are: Property, Server, ServerAspect, ServerLevel, ApplicationComponent, InstalledComponent, VersionTag.")
          success = false
        end
      end
    end
    return success
  end

  def set_property_values_with_holders
    success = true
    unless self.property_values_with_holders.blank?
      property_values_with_holders.each do |pv|
        # use the method to set these because it has protection, updates, etc. All blank values to be set
        # in case the user wants to clear a value
        update_value_for_object(pv[:value_holder_object], pv[:value]) unless pv[:value_holder_object].blank? || pv[:value].nil?
      end
    end
    return success
  end
end

