################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class Group < ActiveRecord::Base

  include SoftDelete
  include HasDefault
  include FilterExt

  DEFAULT_GROUP_POSITION = 1
  ROOT_NAME = 'Root'

  has_many :user_groups, :dependent => :destroy
  has_many :resources, :class_name => 'User', :through => :user_groups, :source => :user
  has_many :users, through: :user_groups
  has_many :placeholder_resources, :class_name => 'PlaceholderResource', :through => :user_groups, :source => :user
  has_many :team_groups
  has_many :teams, through: :team_groups
  has_many :group_roles, dependent: :destroy
  has_many :roles, through: :group_roles
  has_many :permissions, through: :roles

  attr_accessible :name, :email, :resources, :resource_ids, :active, :team_ids, :role_ids, :root, :updated_at

  acts_as_audited protect: false

  validates :name,
            :presence => true,
            :uniqueness => {:case_sensitive => false}

  validate :name_is_not_a_negative_number
  validate :group_is_not_stolen, if: :updated_at_changed?
  after_save :update_date

  #validates_with GroupNameRootValidator, name: ROOT_NAME

  before_destroy :prevent_destroying_with_name_root
  before_validation :prevent_update, on: :update, unless: proc { active_was || active_changed? }

  scope :root_groups, where(root: true)
  scope :name_order, order('groups.name ASC')
  scope :filter_by_name, lambda { |filter_value| where('LOWER(groups.name) like ?', filter_value.downcase) }
  scope :of_teams, lambda { |teams|
    joins(:team_groups).where(team_groups: {team_id: teams}).uniq
  }

  is_filtered cumulative: [:name], boolean_flags: {default: :active, opposite: :inactive}

  def root_group?
    self.root
  end

  def self.default_group
    where(position: DEFAULT_GROUP_POSITION).first || Group.default
  end

  def self.search(key = nil)
    if key.present?
      includes(:roles, :teams).where('LOWER(groups.name) LIKE :key OR LOWER(roles.name) LIKE :key OR LOWER(teams.name) LIKE :key', key: "%#{key.downcase}%")
    else
      includes(:roles, :teams)
    end
  end

  def self.workstreams_in_group(group)
    if PostgreSQLAdapter || OracleAdapter
      s_concat = "(u.last_name || ', ' || u.first_name)"
    elsif MsSQLAdapter
      s_concat = "(u.last_name + ', ' + u.first_name)"
    end
    find_by_sql <<-SQL
      select w.id as stream, w.resource_id, w.activity_id,
      (case when u.type is null then #{s_concat} else u.type end) as "resource",
      a.name as "activity" from workstreams w INNER join activities a ON w.activity_id = a.id
      INNER JOIN users u on w.resource_id = u.id
      where resource_id IN (select user_id from user_groups where type is null AND group_id = #{group.id})
      order by u.type, u.last_name, u.first_name, a.name
    SQL
  end

  def self.root_group_ids
    root_groups.pluck(:id)
  end

  def view_object
    @view_object ||= GroupView.new(self)
  end

  def before_deactivate_hook
    true
  end
  alias :can_be_deactivated? :before_deactivate_hook

  def make_default!
    DefaultGroupSetter.new(self).make_default_and_assign_to_default_team
  end

  private

  def prevent_update
    errors.add(:base, I18n.t('group.edit_error'))
    false
  end

  def prevent_destroying_with_name_root
    name != ROOT_NAME
  end

  def name_is_not_a_negative_number
    errors.add(:name, 'cannot begin with a negative number') if name.to_i < 0
  end

  def group_is_not_stolen
    is_stolen = updated_at.to_i < updated_at_was.to_i
    errors.add(:base, I18n.t('activerecord.errors.object.stolen')) if is_stolen
  end

  def update_date
    self.touch if persisted?
  end
end
