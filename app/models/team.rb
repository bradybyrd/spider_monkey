################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Team < ActiveRecord::Base
  include FilterExt
  include SoftDelete

  DEFAULT_TEAM_ID = 0

  validates :name,
            :presence => true,
            :uniqueness => {:case_sensitive => false},
            if: :active

  has_many :development_teams,  :dependent => :destroy # why a development team?..
  has_many :assigned_apps,      :dependent => :destroy # applications that *users* have access to
  has_many :apps,               :through => :development_teams, after_remove: :prevent_removing_app_that_result_in_app_having_no_groups
  has_many :members,            :through => :assigned_apps, :source => :user
  has_many :member_apps,        :through => :assigned_apps, :source => :app, :uniq => true

  has_many :team_groups,              dependent: :destroy
  has_many :groups,                   through: :team_groups, after_remove: :prevent_removing_group_that_result_in_app_having_no_groups
  has_many :team_group_app_env_roles, through: :team_groups
  has_many :roles_per_app_env,        through: :team_group_app_env_roles, source: :role
  has_many :roles,                    through: :groups, uniq: true
  has_many :users,                    through: :groups, source: :resources

  before_validation :prevent_update, on: :update, unless: proc { active_was || active_changed? }

  attr_accessible :user_id, :name, :app_ids, :group_ids,
    :role_environment_mappings, :team_group_app_env_roles, :app_roles,
    :user_selection, :active
  attr_accessor :app_roles, :user_selection

  scope :filter_by_name, lambda { |filter_value| where("LOWER(teams.name) like ?", filter_value.downcase) }

  scope :name_order, order('name ASC')

  scope :ids_only, pluck('teams.id').uniq

  scope :apps_and_users, (lambda do |_app_ids|
      select("apps.id as app_id").select("users.id as user_id").
      extending(QueryHelper::WhereIn).
      joins(:apps).joins(groups: :resources).
      where_in("apps.id", _app_ids)
  end)

  is_filtered cumulative: [:name], boolean_flags: {default: :active, opposite: :inactive}

  acts_as_audited protect: false

  HUMANIZED_ATTRIBUTES = {
    :app_ids => "Application list",
    :group_ids => "Group List",
    :user_ids => "User List"
  }

  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def self.search(key = nil)
    if key.present?
      includes(:apps, :groups).where('LOWER(teams.name) LIKE :key OR LOWER(groups.name) LIKE :key', key: "%#{key.downcase}%")
    else
      includes(:apps, :groups)
    end
  end

  def self.default
    Team.where(id: DEFAULT_TEAM_ID).first
  end

  def prevent_update
    errors.add(:base, 'You cannot update an inactive Team')
    false
  end

  def inactive?
    !active
  end

  def after_activate
    update_apps_users
  end

  def after_deactivate
    update_apps_users
  end

  def update_apps_users
    apps.each do |app|
      user_ids = app.team_users.where(teams: {active: true}).pluck(:id).uniq
      app.users = User.find(user_ids)
    end
  end

  def add_users_to_team
    users.each do |user|
      apps.each do |app|
        user.set_access_to_app(app, id)
      end
    end
  end

  def remove_apps_from_assigned_apps
    removed_app_ids = member_app_ids - app_ids
    unless removed_app_ids.blank?
      AssignedApp.delete_with_callback("app_id IN (#{removed_app_ids.join(',')}) AND team_id = #{id}")
    end
  end

  def remove_users_from_team
    (members - users).each do |user|
      AssignedApp.delete_with_callback("user_id = #{user.id} AND team_id = #{id}")
    end
  end

  def manage_apps_and_users(action, params)
    _app_ids      = Array(params[:app_ids]).map(&:to_i)
    old_app_users = Team.active.apps_and_users(_app_ids).group_by(&:app_id)

    result = yield(self, _app_ids) if block_given? # team.app_ids -= rem_app_ids

    new_app_users = Team.active.apps_and_users(_app_ids).group_by(&:app_id)

    App.find(_app_ids.any? ? _app_ids : app_ids).each do |app|
      new_user_ids = new_app_users[app.id].nil? ? [] : new_app_users[app.id].map(&:user_id).uniq
      old_user_ids = old_app_users[app.id].nil? ? [] : old_app_users[app.id].map(&:user_id).uniq
      if action == :add
        app.users += User.find(new_user_ids - old_user_ids)
      elsif  action == :remove
        app.users -= User.find(old_user_ids - new_user_ids) if app.users.present?
      end
    end

    result
  end

  def add_group(group)
    self.groups |= Array(group)

    apps.includes(:users).each do |app|
      app.users |= User.find(group.user_ids)
    end
  end

  def default?
    id == DEFAULT_TEAM_ID
  end

  def before_deactivate_hook
    !self.default?
  end

  def team_policy
    TeamPolicy.new(self)
  end

  def role_environment_mappings
    team_group_app_env_roles
  end

  def role_environment_mappings=(new_mappings)
    self.class.transaction do
      existing_ids = team_group_app_env_roles.pluck(:id)
      ids = associate_specified_team_group_app_env_roles(new_mappings)
      remove_unspecified_team_group_app_env_role_mappings(existing_ids - ids)
    end
  end

  private

  def associate_specified_team_group_app_env_roles(mappings)
    Array(mappings).map do |mapping|
      associate_team_group_app_env_role(mapping)
    end
  end

  def associate_team_group_app_env_role(mapping)
    team_group = self.team_groups.where(group_id: mapping["group_id"]).first_or_create
    app_env = ApplicationEnvironment.where(app_id: mapping["app_id"], environment_id: mapping["environment_id"]).first_or_create
    mapping = TeamGroupAppEnvRole.set(team_group_id: team_group.id, application_environment_id: app_env.id, role_id: mapping["role_id"])
    mapping.id
  end

  def remove_unspecified_team_group_app_env_role_mappings(remove_these_ids)
    TeamGroupAppEnvRole.where(id: remove_these_ids).delete_all
  end

  def prevent_removing_group_that_result_in_app_having_no_groups(group)
    groups << group unless apps.all?(&:have_at_least_one_group)
  end

  def prevent_removing_app_that_result_in_app_having_no_groups(app)
    apps << app if !app.have_at_least_one_group && app.teams.none?
  end
end
