################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
require 'permission_scope'

class ServerAspectGroup < ActiveRecord::Base
  include PermissionScope

  attr_accessible :name, :server_level_id, :server_aspect_ids

  attr_accessor :check_permissions

  has_and_belongs_to_many :server_aspects, join_table: 'sagsas'
  belongs_to :server_level

  validates_with PermissionsPerEnvironmentValidator
  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false }

  scope :sorted, order('name')
  scope :accessible_server_aspect_groups_to_user, lambda { |user_id|
    joins(server_aspects: {environment_servers: { environment: { application_environments: :assigned_apps }}}).where("assigned_apps.user_id = #{user_id}").uniq
  }

  paginate_alphabetically by: :name
  normalize_attributes :name

  def environments_per_server_aspects_for(user)
    user_app_ids = user.apps.map(&:id)
    Environment.active.by_app_env_apps(user_app_ids).by_server_aspects(server_aspect_ids)
  end
end
