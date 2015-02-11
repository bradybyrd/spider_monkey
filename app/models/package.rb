class Package < ActiveRecord::Base
  include SoftDelete
  include QueryHelper
  include FilterExt

  concerned_with :import_app_packages

  has_many :package_instances, dependent: :destroy
  has_many :package_properties, dependent: :destroy
  has_many :references, dependent: :destroy
  has_many :steps


  has_many :application_packages, dependent: :destroy
  has_many :applications, :through => :application_packages, source: :app

  has_many :properties, :through => :package_properties, :order => 'package_properties.position'
  accepts_nested_attributes_for :properties, :allow_destroy => true

  before_validation :find_property

  # FIXME: the concept of "not from rest" should be depricated and removed in later versions
  # as the code should work equally well in both modes with simple tests, not explicit flag setting.
  attr_accessor :not_from_rest, :current_value,
                :property_name, :property_lookup_failed

  attr_accessible :name, :not_from_rest, :current_value, :property_name, :property_ids, :property_lookup_failed, :active, :instance_name_format, :next_instance_number

  def next_instance_must_be_greater_than_0
    if next_instance_number
      if next_instance_number < 1
        errors.add(:next_instance_number, "must be greater than 0")
      end
    end
  end

  validate :next_instance_must_be_greater_than_0

  validates :name,
            :presence => true,
            :length => {:maximum => 255},
            :uniqueness => {:case_sensitive => false}

  validates :instance_name_format,
            :presence => true,
            :length => {:maximum => 255}

  validates :next_instance_number,
            :presence => true,
            :numericality => {only_integer: true, less_than: 2147483647}

  after_initialize :default_values

  scope :accessible_packages_to_user, ->(user_id) do
    joins(application_packages: { app: :assigned_apps }).where('assigned_apps.user_id' => user_id)
  end

## Add the defaulted next instance on create
  def default_values

    ## Need to check for existence in cases of multipicker usage
    if self.has_attribute? :next_instance_number
      self.next_instance_number ||= 1
      self.instance_name_format ||= '0.0.0.[#]'
    end

  end


## For FilterExt
  is_filtered cumulative_by: {name: :for_name, property_name: :for_property_name, app_name: :for_app_name},
              boolean_flags: {default: :active, opposite: :inactive}

## For FilterExt
  scope :for_name, lambda { |package_name|
    {:conditions => ['UPPER(packages.name) like ?', package_name.upcase]}
  }

## For FilterExt
  scope :for_property_name, lambda { |property_name|
    {:include => :properties, :conditions => ['properties.name like ?', property_name]}
  }

## For FilterExt
  scope :for_app_name, lambda { |app_name|
    { include: :applications, conditions: ['apps.name like ?', app_name] }
  }


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

  def find_or_create_reference_named(name)
    references.find_or_create_by_name(name)
  end

  def find_or_initialize_instance_named(name)
    package_instances.find_or_initialize_by_name(name)
  end

  def deactivate!
    if destroyable?
      self.update_attribute(:active, false)
      true
    else
      errors.add(:base, I18n.t('package.errors.inactivate_condition'))
      false
    end
  end

  def destroyable?
    self.application_packages.empty?
  end

  def increment_next_instance_number
    self.next_instance_number += 1
  end

  def latest_package_instance
    package_instances.last
  end

end
