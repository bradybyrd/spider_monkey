require 'date'
class PackageInstance < ActiveRecord::Base
  include SoftDelete
  include FilterExt

  self.per_page = 30

  attr_accessible :active, :instance_name, :name, :selected_reference_ids, :reference_ids, :package_name,
                  :properties_with_values, :properties_with_values_lookup_failed,
                  :remove_reference_ids,
                  :reference_properties_with_values,:reference_properties_with_values_lookup_failed

  belongs_to :package

  has_many :apps, through: :package, source: :applications
  has_many :instance_references, dependent: :destroy

  has_many :property_values, :as => :value_holder, :dependent => :destroy, :conditions => 'deleted_at IS NULL'
  has_many :current_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NULL'
  has_many :deleted_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NOT NULL'

  has_many :properties, :through => :property_values

  has_many :steps
  has_many :requests, through: :steps, order: "requests.created_at DESC"

  before_validation :find_package
  validate          :lookups_succeeded
  validate :package_id_not_changed

  # if the validations all went well, we can update the properties
  after_save :update_properties_with_values

  # FIXME: the concept of "not from rest" should be depricated and removed in later versions
  # as the code should work equally well in both modes with simple tests, not explicit flag setting.
  attr_accessor :not_from_rest, :selected_reference_ids, :reference_ids, :package_name,
                :package_lookup_failed,
                :properties_with_values, :properties_with_values_sanitized, :properties_with_values_lookup_failed,
                :remove_reference_ids,
                :reference_properties_with_values, :reference_properties_with_values_lookup_failed

  ## For FilterExt
  is_filtered cumulative_by: {name: :for_name, package_name: :for_package_name, property_name: :for_property_name},
    boolean_flags: {default: :active, opposite: :inactive}

  ## For FilterExt
  scope :for_name, lambda { |package_instance_name|
    { conditions: ['UPPER(package_instances.name) like ?', package_instance_name.upcase] }
  }

  scope :for_package_name, lambda { |package_name|
    { include: :package, conditions: ['UPPER(packages.name) like ?', package_name.upcase] }
  }

  scope :for_property_name, lambda { |property_name|
    { include: :properties, conditions: ['properties.name like ?', property_name] }
  }

  validates :package, presence: true
  validates :name,
    :presence => true,
    :length => {:maximum => 255},
    :uniqueness => {:case_sensitive => false, :scope => [:package_id] }

  scope :accessible_instances_of_package, ->(user_id, package_id) do
    joins(package: { application_packages: { app: :assigned_apps }}).
      where(assigned_apps: { user_id:  user_id }).
      where(packages: { id: package_id })
  end

  #
  # Returns package references that are not used in this package_instance.
  # 
  def available_package_references
     if self.instance_references.empty?
       Reference.find( :all, :conditions => [ 'package_id = (?)', self.package_id ] )
     else
       Reference.find( :all, :conditions => [ 'package_id = (?) and id not in (?)', self.package_id, self.instance_references.map{ | ri | "#{ri.reference_id}" }  ] )
     end
  end

  def recent_activity
    requests.to_a.uniq.take(3)
  end

  #
  # Text replacements for the name
  #
  def format_name( format_str, next_inst_number )
    self.name = format_str.gsub( "[#]", next_inst_number.to_s )
    self.name = DateTime.now.strftime( self.name )
  end   

  #
  # Finds the instance reference based on the reference id of the package
  #
  def find_reference( ref_id )
    self.instance_references.find { | inst_ref | inst_ref.reference_id == ref_id.to_i }
  end

  def find_or_initialize_reference_named(name)
    self.instance_references.find_or_create_by_name(name)
  end

  def copy_property_from_package
    package_properties = package.properties
    unless package_properties.blank?
      package_properties.each do | property |
        property_value = PropertyValue.new
        property_value.property_id = property.id
        property_value.value_holder = self
        property_value.value = property.default_value
        property_values << property_value
      end
    end                     
  end



  #
  # Copy references and the override property values into the instance
  # if the reference is already in the package instance it will be ignored.
  #
  def copy_references( reference_ids )
    unless reference_ids.blank?
      reference_ids.each do | id |
        unless self.find_reference( id )
          r = Reference.find id

          raise "Reference is not a member of package specified" unless r.package == self.package

          inst_ref = self.instance_references.new
          inst_ref.reference = r
          inst_ref.server = r.server
          inst_ref.uri = r.uri
          inst_ref.name = r.name
          inst_ref.resource_method = r.resource_method

          ## Copy the property values!!!
          reference_property_values = r.property_values
          unless reference_property_values.blank?
            reference_property_values.each do | p_val |
              property_value = p_val.dup
              property_value.value_holder = inst_ref
              property_value.value = p_val.value
              inst_ref.property_values << property_value
            end
          end

          inst_ref.save!
        end

      end
    end
  end


  #
  # Remove references from the package_instance.   Note that these are
  # the reference id from the package,  not the package instance reference id
  #
  def remove_references( reference_ids )
    unless reference_ids.blank?
      reference_ids.each do | id |
        ref_to_delete = self.find_reference( id )
        ref_to_delete.delete if ref_to_delete
      end
    end
  end


  # convenience finder (mostly for REST clients) that allows you to pass a package_name
  # and a component_name and have us look up the correct application component
  def find_package
    self.package_lookup_failed = false
    unless self.package_name.blank?
      my_package = Package.for_name( self.package_name ).try(:first)
      unless my_package.blank?
        self.package = my_package
      else
        self.package_lookup_failed = true
      end
    end

    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end

  def lookups_succeeded

    self.errors.add(:package, I18n.t('package_instance.package_not_found')) if self.package_lookup_failed
    self.errors.add(:properties_with_values, "could not be found. Check that the property and the values are valid for this package instance.") if self.properties_with_values_lookup_failed
    self.errors.add(:reference_properties_with_values, "could not be found. Check that the reference and property and the values are valid for this package instance.") if self.properties_with_values_lookup_failed
  end

  ## mainly to support rest client
  def find_property_by_name( prop_name )
    self.properties.find { | prop | prop.name == prop_name }
  end

  # convenience finder (mostly for REST clients) that allows you to pass property value pairs
  # and have the matching properties looked up and updated safely
  # Note that this must be called after the entity is saved.
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
          my_property = self.find_property_by_name(property_name.to_s)
          # if the property is found, change its value
          if my_property.blank?
            self.properties_with_values_lookup_failed = true
            self.errors.add(:properties_with_values, "could not be found. Check that the property and the values are valid for this package instance.")
          else
            self.properties_with_values_sanitized << { :property => my_property, :value => p_value }
          end
        else
          # otherwise we likely have the short form suitable for json and one work XML elements
          pv.each_pair do |p_name, p_value|
            # find the property
            my_property = self.find_property_by_name(p_name.to_s)
            Rails.logger.info("-------my_property: " + my_property.inspect)
            # if the property is found, change its value
            if my_property.blank?
              self.properties_with_values_lookup_failed = true
              self.errors.add(:properties_with_values, "could not be found. Check that the property and the values are valid for this package instance.")
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
    self.find_properties_with_values

    # don't do anything if there was an error looking them up or no properties were passed
    unless self.properties_with_values_lookup_failed || self.properties_with_values_sanitized.blank?
      # looped through the passed pairs
      self.properties_with_values_sanitized.each do |my_property_row|
        my_property = my_property_row[:property]
        my_value = my_property_row[:value]
        # if the property is found, change its value
        unless my_property.blank?
          my_property.update_value_for_package_instance(self, my_value)
        end
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    return true
  end


  #
  # If supplied an array of reference and property values, update the property values on the reference instances
  #
  def update_reference_properties_with_values
    self.reference_properties_with_values_lookup_failed = false
    unless reference_properties_with_values.blank?
      reference_properties_with_values.each do | ref_prop_val |
        my_ref_id = ref_prop_val[:ref_id]
        my_property_name = ref_prop_val[:property_name]
        my_value = ref_prop_val[:property_value]

        ref_to_update = self.find_reference( my_ref_id )
        unless ref_to_update
          self.reference_properties_with_values_lookup_failed = false
          self.errors.add(:reference_properties_with_values, "could not be found. Check that the reference, property and the values are valid for this package instance.")
          break
        end

        ref_property = ref_to_update.find_property_by_name my_property_name
        unless ref_property
          self.reference_properties_with_values_lookup_failed = false
          self.errors.add(:reference_properties_with_values, "could not be found. Check that the reference, property and the values are valid for this package instance.")
          break
        end
        ref_property.update_value_for_instance_reference(ref_to_update, my_value)
      end
    end
  end

  def update_reference_properties_with_values!
    update_reference_properties_with_values
    raise StandardError.new(errors.full_messages) if self.errors.present?
  end

  def self.import_app_request(step, xml_hash)
    if xml_hash["package_instance"]
      package = Package.find_by_name  xml_hash["package"]["name"]
      if package.present?
        package_instance = find_by_name xml_hash["package_instance"]["name"]
        step.package_instance_id = package_instance.id
      end
    end
  end

  def destroyable?
    self.requests.empty?
  end

  def used?
    self.requests.present?
  end

  def active?
    active
  end

  def find_instance_reference_for_reference(reference)
    instance_references.where(reference_id: reference.id).first
  end

  def package_id_not_changed
    if package_id_changed? && self.persisted?
      errors.add(:package_id, I18n.t('package_instance.package_change_not_allowed'))
    end
  end

  def package_reference_ids
    instance_references.pluck( :reference_id )
  end

end
