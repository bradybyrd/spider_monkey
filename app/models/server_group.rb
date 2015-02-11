################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ServerGroup < ActiveRecord::Base
  include SoftDelete
  include ServerAspectFacade
  include ServerUtilities
  include FilterExt

  paginate_alphabetically :by => :name

  has_many :server_aspects, :as => :parent

  has_and_belongs_to_many :servers
  has_and_belongs_to_many :active_servers, class_name: Server, conditions: { active: true }

  has_many :environment_server_groups, dependent: :destroy
  has_many :environments, through: :environment_server_groups

  #FIXME: default_server_group_id links server groups to installed
  # components, so shouldn't we have a dependent relation that gets
  # nullified when a server group is deleted?

  attr_accessible :name, :description, :server_ids, :environment_ids, :server_aspect_ids, :active

  validates :name,
            :presence => true,
            :uniqueness => {:case_sensitive => false}
  normalize_attributes :name

  scope :ordered, ->{ order('LOWER(name) ASC') }
  scope :active, ->{ where(:active => true).ordered }
  scope :inactive, ->{ where(:active => false).ordered }

  scope :filter_by_name, lambda { |filter_value| where("LOWER(server_groups.name) like ?", filter_value.downcase) }

  is_filtered cumulative: [:name], boolean_flags: {default: :active, opposite: :inactive}

end
