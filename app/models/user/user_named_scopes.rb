################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################
class User < ActiveRecord::Base
  include FilterExt

  def self.search_user(condition)
    if PostgreSQLAdapter || OracleAdapter
      name = "users.first_name || ' ' || users.last_name"
      reverse_name = "users.last_name || ' ' || users.first_name"
    elsif MsSQLAdapter
      name = "users.first_name +  ' ' +  users.last_name"
      reverse_name = "users.last_name +  ' ' +  users.first_name"
    end
    self.includes(:groups).where('LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(login) LIKE ? OR LOWER(groups.name) LIKE ?' +
      " OR LOWER(#{name}) LIKE ? OR LOWER(#{reverse_name}) LIKE ?", '%'+condition+'%', '%'+condition+'%', '%'+condition+'%',
      '%'+condition+'%', '%'+condition+'%', '%'+condition+'%')
  end

  def self.by_keyword(condition)
    condition = condition.try(:downcase)
    if PostgreSQLAdapter || OracleAdapter
      name = "users.first_name || ' ' || users.last_name"
      reverse_name = "users.last_name || ' ' || users.first_name"
    elsif MsSQLAdapter
      name = "users.first_name +  ' ' +  users.last_name"
      reverse_name = "users.last_name +  ' ' +  users.first_name"
    end
    self.where('LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(login) LIKE ? OR ' + "  LOWER(#{name}) LIKE ? OR LOWER(#{reverse_name}) LIKE ?",
      '%'+condition+'%', '%'+condition+'%', '%'+condition+'%', '%'+condition+'%', '%'+condition+'%')
  end

  def self.managed_by(manager)
    if manager.admin?
      self.where('users.id <> ? AND users.type IS NULL', manager)
    else
      self.joins('INNER JOIN user_groups ON users.id = user_groups.user_id').joins('INNER JOIN group_management ON user_groups.group_id = group_management.group_id').
        where('users.id = group_management.manager_id AND users.id = ? AND users.type = ?', manager, nil)
    end
  end

  def self.managed_by_including_placeholders_orphan(manager)
    if manager.admin?
      self.where('users.id <> ?', manager)
    else
      if OracleAdapter
        self.joins('INNER JOIN user_groups ON users.id = user_groups.user_id').
            joins('INNER JOIN group_management ON user_groups.group_id = group_management.group_id').
            where('users.id = group_management.manager_id AND users.id = ?', manager)
      else
        self.joins('INNER JOIN user_groups ON users.id = user_groups.user_id').
            joins('INNER JOIN group_management ON user_groups.group_id = group_management.group_id').
            joins('INNER JOIN users AS managers ON managers.id = group_management.manager_id').
            where('managers.id = group_management.manager_id AND managers.id = ?', manager)
      end
    end
  end

  # BJB 3/30/10 Reworked to be compatible with both oracle and mysql
  def self.managed_by_including_placeholders(manager)
    if manager.admin?
      self.where('users.id <> ?', manager)
    else
      self.joins('INNER JOIN user_groups ON users.id = user_groups.user_id').
        where('users.active = 1 AND user_groups.group_id IN (select group_id from group_management where manager_id = ?)', manager)
    end
  end

  scope :by_first_name, order('first_name')
  scope :by_last_name,  order('last_name')
  scope :order_by_name,  -> { by_first_name.by_last_name }
  scope :index_order, order('type DESC, last_name ASC, first_name ASC')
  scope :unmanaged, joins('LEFT OUTER JOIN user_groups ON user_groups.user_id = users.id').where('user_groups.id IS NULL')

  scope :of_groups, lambda { |groups|
    joins(:user_groups).where(user_groups: {group_id: groups}).uniq
  }
  scope :selected_users_ids, lambda { |users_list| where('users.id' => users_list) }

  scope :with_workstreams, includes(:workstreams).where("#{User.quoted_table_name}.id = #{Workstream.quoted_table_name}.resource_id")
  scope :not_placeholder, where('users.type IS NULL')
  scope :currently_logged_in, lambda { |user_id| where('users.last_response_at > ? AND users.id != ?', DEFAULT_MINUTES_UNTIL_OFFLINE.minutes.ago, user_id) }

  scope :placeholder, conditions: {type: 'PlaceholderResource'}

  scope :select_id_name_email_login, select('users.id, users.first_name, users.last_name, users.email, users.login')

  # active is a special scope that is used by default in all searches; if false, we show all
  scope :active, where('users.active' => true)
  scope :inactive, where('users.active' => false)
  scope :admins, lambda { joins(:groups).where(groups: {root: true}) }
  scope :root_users, admins
  scope :roots, admins

  scope :filter_by_login, lambda { |filter_value| where('LOWER(users.login) like ?', filter_value.downcase) }
  scope :filter_by_last_name, lambda { |filter_value| where('LOWER(users.last_name) like ?', filter_value.downcase) }
  scope :filter_by_first_name, lambda { |filter_value| where('LOWER(users.first_name) like ?', filter_value.downcase) }
  scope :filter_by_email, lambda { |filter_value| where('LOWER(users.email) like ?', filter_value.downcase) }

  is_filtered cumulative: [:first_name, :last_name, :email],
              cumulative_by: {keyword: :by_keyword},
              boolean_flags: {default: :active, opposite: :inactive},
              specific_filter: :user_specific_filters

  def self.user_specific_filters(entities, adapter_column, filters = {})
    if adapter_column.value_to_boolean(filters[:root])
      entities.root_users
    else
      entities
    end
  end

  # oracle and postgres are fussy about group_by -- oracle will not allow clob field (Rails text) in so these need to be truncated
  # and converted, oracle does not want any select fields that are not in the group by (so clobs need to be chopped there), and
  # postgres requires all fields in the select to be in the group_by.  Hence a helper function to provide those fields as needed.
  def self.groupable_fields
    return self.columns.collect{|c| c.type == :text && (PostgreSQLAdapter || OracleAdapter) ? "CAST(users.#{c.name} AS varchar(4000))" : "users.#{c.name}" }.join(', ')
  end

  def self.get_current_users
    User.select_id_name_email_login.active.currently_logged_in(current_user.id).index_order.limit(100)
  end
end
