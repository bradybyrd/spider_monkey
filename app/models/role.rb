################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Role < ActiveRecord::Base
  include SoftDelete
  include FilterExt

  has_many :role_permissions
  has_many :permissions, through: :role_permissions

  has_many :group_roles
  has_many :groups, through: :group_roles
  has_many :users, through: :groups
  has_many :teams, through: :groups
  has_many :team_group_app_env_roles

  scope :by_user, ->(user) { Role.joins(:groups => :user_groups).where('user_groups.user_id = ?', user.id) }

  scope :active, where(active: true)
  scope :inactive, where(active: false)
  attr_accessible :name, :description, :permission_ids

  acts_as_audited protect: false

  def permission_ids=(new_ids)
    delete_these_ids = permissions.pluck(:id) - new_ids.map(&:to_i)
    delete_these_ids.each do |delete_this_id|
      role_permissions.where(permission_id: delete_this_id).destroy_all
    end
    super
  end

  validates :name,
            :presence => true,
            :uniqueness => {:case_sensitive => false},
            :length => { :maximum => 255 }
  validates :description,
            :length => { :maximum => 255 }

  SmartRelease = [
      ['Deployer', 'deployer'],
      ['Coordinator','deployment_coordinator'],
      ['Requestor', 'requestor'],
      ['User', 'user'],
      ['Executor', 'executor'],
      ['Not Visible', 'not_visible']
  ]

  is_filtered cumulative: [:name],
              boolean_flags: {default: :active, opposite: :inactive}

  scope :filter_by_name, lambda { |filter_value| where("LOWER(roles.name) like ?", filter_value.downcase) }

  self.per_page = 20

  def self.search(key = nil)
    if key.present?
      includes(:groups, :teams).where('LOWER(roles.name) LIKE :key OR LOWER(groups.name) LIKE :key OR LOWER(teams.name) LIKE :key', key: "%#{key.downcase}%")
    else
      includes(:groups, :teams)
    end
  end

  def self.orderable_column_names
    ['name']
  end

  def group_names
    groups.order(:'groups.id').pluck(:name).join(', ')
  end

  def team_names
    teams.order(:'teams.id').pluck(:name).join(', ')
  end

  def deactivatable?
    groups.none?
  end

  def permissions_tree
    @permissions_tree ||= ::PermissionsList.new.permissions_tree
  end

  private

  def before_deactivate_hook
    deactivatable?
  end

end
