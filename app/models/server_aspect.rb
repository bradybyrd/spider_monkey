################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ServerAspect < ActiveRecord::Base
  include ServerUtilities

  paginate_alphabetically :by => :name

  belongs_to :parent, :polymorphic => true
  belongs_to :server_level

  has_many :server_aspects, :as => :parent, :dependent => :destroy
  has_many :property_values, :as => :value_holder, :dependent => :destroy
  has_many :properties_with_values, :through => :property_values, :source => :property, :conditions => { 'active' => true }
  has_many :current_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NULL'
  has_many :deleted_property_values, :as => :value_holder, :class_name => 'PropertyValue', :dependent => :destroy, :conditions => 'deleted_at IS NOT NULL'

  has_many :environment_servers, :dependent => :destroy, :conditions => 'environment_servers.server_id is NULL'
  has_many :environments, :through => :environment_servers

  has_and_belongs_to_many :installed_components, :join_table => 'icsas'
  has_and_belongs_to_many :groups, :class_name => "ServerAspectGroup", :join_table => 'sagsas'

  validates :name,
            :presence => true,
            :uniqueness => {:scope => [:parent_type, :parent_id], :case_sensitive => false}
  validates :parent,
            :presence => true

  normalize_attributes :name

  attr_protected :server_level_id

  scope :name_order, order("#{quoted_table_name}.name")
  scope :server_level_id_equal, lambda{ |id|
    where(:server_level_id => id)
  }

  def self.with_environments(*envs)
    includes(:environment_servers).where('environment_servers.environment_id' => envs.flatten)
  end

  def self.with_apps(*apps)
    apps = apps.flatten.compact
    if apps.empty?
      all
    else
      includes(:installed_components => :application_component).where('application_components.app_id' => apps)
    end
  end

  delegate :properties, :to => :server_level
  delegate :name, :to => :server_level, :prefix => :level

  def self.on_component_in_environment(component, environment)
    application_component_ids =
      ApplicationComponent.all(:select => "#{ApplicationComponent.quoted_table_name}.id", :conditions => { :component_id => component.id }).map { |ac| ac.id }

    application_environment_ids =
      ApplicationEnvironment.all(:select => "#{ApplicationEnvironment.quoted_table_name}.id", :conditions => { :environment_id => environment.id }).map { |ae| ae.id }

    ServerAspect.all(:include => :installed_components,
                     :conditions => ["#{InstalledComponent.quoted_table_name}.application_component_id IN (?) AND
                                     #{InstalledComponent.quoted_table_name}.application_environment_id IN (?)",
                                     application_component_ids, application_environment_ids])
  end

  def self.find_by_type_and_id type_and_id_string
    type, id = type_and_id_string.split('::')
    type.constantize.find_by_id(id)
  end

  def type_and_id
    "ServerAspect::#{id}"
  end

  def parent_type_and_id
    parent.try(:type_and_id)
  end

  def parent_type_and_id=(type_and_id_string)
    self.parent_type, self.parent_id = type_and_id_string.split('::')
  end

  def full_name
    "#{parent.is_a?(Server) ? parent.name : parent.server.name}:#{name}"
  end

  def server
    return if parent.is_a? ServerGroup
    parent.is_a?(Server) ? parent : parent.server
  end

  def servers
    return parent.servers.active if parent.is_a? ServerGroup
    parent.is_a?(Server) ? [parent] : parent.servers
  end

  def components
    installed_components.map { |ic| ic.component }
  end

  def available_environments
    Array(parent.try(:environments))
  end

  def path
    parent.path << self
  end

  def path_string
    path.map { |s| s.name }.join ':'
  end

  def SUPPRESS_literal_property_value_for(property)
    current_property_values.find_by_property_id(property.id).try(:value) || property.default_value
  end

  def update_property_value_for(property, value)
    property.update_value_for_object(self, value)
  end

  def self.alphabetical_server_levels_group(id, letter = nil)
    find(:all, :conditions => ["server_level_id = ? AND #{@attribute.to_s} LIKE ?", "#{id}", "#{letter || first_letter}%"], :order => @attribute )
  end

  def self.pagination_servers_letter(id,search_param)
     where("server_aspects.server_level_id = #{id}").name_like("#{search_param}%").order('server_aspects.name asc').group_by {
      |group| group.send(:name)[0].chr.upcase}.keys
  end

  def self.pagination_search_server_levels_letter(id,key)
    pagination_servers_letter(id,key).first
  end

  def self.pagination_server_levels_letter(id)
    where("server_aspects.server_level_id = #{id}").order('server_aspects.name asc').group_by {|group| group.send(:name)[0].chr.upcase}.keys
  end
end
