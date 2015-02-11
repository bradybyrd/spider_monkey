################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################
require 'sortable_model'

class Environment < ActiveRecord::Base
  include SoftDelete
  include WithDefault
  include QueryHelper
  include FilterExt
  # TODO: RJ: Rails 3: Log activities is disabled because of plugin incompatibility
  #log_activities

  concerned_with :environment_state_machine

  REQUEST_STATES = [
      ENV_TO_CLOSED = %W(), # none for now; started problem cancelled
      ENV_TO_OPENED = %W(created planned started hold problem cancelled complete)
  ]

  DEFAULT_NAME = '[default]'

  belongs_to :default_server_group, class_name: 'ServerGroup'
  belongs_to :environment_type

  has_many :requests
  has_many :application_environments, dependent: :destroy
  has_many :installed_components, through: :application_environments
  has_many :application_components, through: :installed_components
  has_many :available_components, through: :application_components, source: :component
  has_many :apps, through: :application_environments
  has_many :environment_servers, dependent: :destroy
  has_many :servers, through: :environment_servers
  has_many :plan_env_app_dates
  has_many :packages,                 through: :apps
  has_many :references,               through: :packages
  has_many :server_groups, through: :environment_server_groups
  has_many :active_server_groups, through: :environment_server_groups, source: :server_group, conditions: { active: true }

  has_many :environment_server_groups, dependent: :destroy

  has_many :active_environment_servers, through: :servers, source: :environment_servers,
           conditions: { 'servers.active' => true }

  has_many :assigned_apps, through: :application_environments

  # routes are sequential/parallel sets of environments
  has_many :route_gates, order: :position, dependent: :destroy
  has_many :routes, through: :route_gates

  # a polymorphic relationship with step_execution_conditions to act as a type of constraint on their contents
  has_many :constraints, as: :constrainable, dependent: :destroy

  has_many :deployment_window_events, class_name: DeploymentWindow::Event, foreign_key: :environment_id

  attr_accessible :name, :server_ids, :server_group_ids, :default, :active, :default_server_group_id,
                  :environment_type_id, :environment_type, :deployment_policy

  validates :name,
            presence: true,
            uniqueness: {case_sensitive: true}
  validates_length_of :name, maximum: 255
  validate :can_change_deployment_policy?, on: :update
  validate :validate_deactivate, on: :update
  validate :validate_disassociated_server_ids, on: :update

  normalize_attributes :name

  after_save :set_server_ids
  after_save :set_server_group_ids
  after_save :set_default_server


  scope :with_installed_components, includes(:application_environments).includes(:installed_components).where('installed_components.application_environment_id = application_environments.id')

  scope :with_servers, includes(:environment_servers).where('environment_servers.environment_id = environments.id')

  scope :id_equals, lambda { |ids|
    where('environments.id' => ids)
  }

  scope :request_for_current_in_state, lambda{|state|
      joins(:requests).where('deployment_window_events.finish < ?', Time.now).
      where('requests.state in (?)', state.collect{|el| "'#{el}'"}.join(', '))
  }

  before_update :remove_deployment_window_events, if: :deployment_policy_changed?

  sortable_model

  can_sort_by :name, lambda { |asc| order("lower(environments.name) #{asc}") }

  def self.with_apps(*apps)
    apps = apps.flatten
    apps.blank? ? [] : includes(:apps).where('apps.id' => apps)
  end

  scope :name_order, order('name ASC')

  def self.accessible_to_user(user_id, app_id)
    accessible = self.select('DISTINCT ' + Environment.groupable_fields + ', LOWER(environments.name) as l_env_name').
        joins('INNER JOIN application_environments ON application_environments.environment_id = environments.id').
        joins('INNER JOIN assigned_apps ON assigned_apps.app_id = application_environments.app_id ')

    accessible = accessible.where('assigned_apps.user_id' => user_id) if user_id
    accessible = accessible.where('assigned_apps.app_id' => app_id) if app_id
    accessible = accessible.order('LOWER(environments.name) ASC')
    accessible
  end

  scope :for_plan, lambda { |plan_id| select('DISTINCT ' + Environment.groupable_fields).joins(requests: :plan_member).
      where('plan_members.plan_id' => plan_id.to_i).group(Environment.groupable_fields) }

  scope :via_team, where('team_id IS NOT NULL')

  # FIXME: When possible, we should use 4000 varchar fields instead of the less compatible text fields in our migrations.  When that is done, this kind of test can be removed.
  # oracle and postgres are fussy about group_by -- oracle will not allow clob field (Rails text) in so these need to be truncated
  # and converted, oracle does not want any select fields that are not in the group by (so clobs need to be chopped there), and
  # postgres requires all fields in the select to be in the group_by.  Hence a helper function to provide those fields as needed.
  def self.groupable_fields
    return self.columns.reject { |c| DATABASE_RESERVED_WORDS.include?(c.name.upcase) }.collect { |c| c.type == :text && (PostgreSQLAdapter || OracleAdapter) ? "CAST(environments.#{c.name} AS varchar(4000))" : "environments.#{c.name}" }.join(', ')
  end

  scope :filter_by_name, lambda { |filter_value| where('LOWER(environments.name) like ?', filter_value.downcase) }
  scope :filter_by_environment_type_id, lambda { |filter_value| where(environment_type_id: filter_value) }
  scope :filter_by_deployment_window_event_id, ->(deployment_window_event_id) {
    joins(:deployment_window_events).where('deployment_window_events.id = ?', deployment_window_event_id)
  }
  scope :filter_by_deployment_window_series_id, ->(deployment_window_series_id) {
    joins(deployment_window_events: { occurrence: :series }).
        where('deployment_window_series.id = ?', deployment_window_series_id)
  }
  scope :filter_by_deployment_policy, ->(policy) { with_deployment_policy policy }

  scope :with_deployment_policy, ->(policy) { where deployment_policy: policy }
  scope :by_app_env_apps, ->(app_ids) do
    joins(:application_environments).where(application_environments: {app_id: app_ids}).uniq
  end

  scope :by_server_aspects, ->(server_aspect_ids) do
    joins(environment_servers: :server_aspect).where(server_aspects: {id: server_aspect_ids}).uniq
  end

  is_filtered cumulative: [:name, :environment_type_id, :deployment_window_event_id, :deployment_window_series_id, :deployment_policy],
              boolean_flags: {default: :active, opposite: :inactive}

  class << self

    #FIXME: Why is this not a named scope?
    def active_and_used
      find_by_sql <<-SQL
        select * from environments where environments.active = #{RPMTRUE} or exists (select 1 from requests where requests.environment_id = environments.id) order by name
      SQL
    end


    def import_app_request(xml_hash)
      if xml_hash['environment']
        name = xml_hash['environment']['name']
        env = Environment.find_by_name name
        env.id
      end
    end
  end

  def active_deployment_window_series
    DeploymentWindow::Series.active_per_environment(self).as_json(
      only: [:name, :behavior, :aasm_state, :recurrent, :start_at, :finish_at, :duration_in_days],
      include: {
          creator: { only: [:last_name, :first_name] },
      },
      methods: [:schedule_data]
    )
  end

  # convenience method for getting a nice list of route names
  # that should ignore default routes
  def routes_list
    routes.blank? ? '' : self.routes.not_default.in_name_order.map { |r| r.name_with_app }.to_sentence
  end

  def server_ids=(server_ids)
    @server_ids = server_ids.map(&:to_i)
  end

  def server_group_ids=(server_ids)
    @server_group_ids = server_ids.map(&:to_i)
  end

  def default_server_id=(server_id)
    @default_server_id = server_id.to_i
    @default_server_set = true
  end

  def default_server_id
    default_server.id if default_server
  end

  def servers_with_default_first
    servers.active.all(order: 'environment_servers.default_server DESC')
  end

  def server_groups_with_default_first
    if default_server_group_id?
      server_groups.ordered.where('id <> ?', default_server_group_id).unshift(default_server_group)
    else
      server_groups.ordered
    end
  end

  def default_server
    self.default_environment_server.server if self.default_environment_server
  end

  def default_environment_server
    self.environment_servers.find_by_default_server(true)
  end

  def server_associations
    @server_associations = servers + servers.map { |s| s.aspects_below }
    @server_associations.flatten!
  end

  def app_names
    apps.map(&:name)
  end

  def app_names_for(user)
    @app_names = apps_for(user).map(&:name).to_sentence
  end

  def apps_for(user)
    user.apps_with_environment(id)
  end

  # when environments are listed on the application page
  # the view used to check if they had any requests active
  # that would make removing them problematic.  If so, the
  # check box was disabled.  We need to expand that to
  # include routes as well so I am moving this method to
  # the model and adding more conditions
  def can_be_removed_from_app?(app)
    case
      when app.requests.present.with_env_id(self.id).exists? then
        false
      when app.routes.not_default.filter_by_environment_id(self.id).exists? then
        false
      when app.default_route.active_plans.any? then
        false
      else
        true
    end
  end

  # a convenience method for showing the types label on environment
  # tool tips and reports
  def full_label
    label = []
    label << name
    label << " (#{ environment_type.try(:name) || 'Untyped' }"
    label << (environment_type.try(:strict?) ? ' - Strict)' : ')')
    label.compact.join
  end

  def related_request_ids_in_states(states)
    self.requests.where(aasm_state: states).map(&:number)
  end

  # TODO: make this a single query as a scope
  def request_ids_with_active_dw_in_states(states)
    requests      = self.requests.where aasm_state: states
    dw_ids        = requests.pluck(:deployment_window_event_id).uniq
    active_dw_ids = DeploymentWindow::Event.where(id: dw_ids).not_passed.pluck :id

    requests.collect {|r| r.number if active_dw_ids.include? r.deployment_window_event_id }.compact
  end

  def deployment_policy_changed_to(policy)
    self.deployment_policy_changed? and deployment_policy == policy
  end

  def can_change_deployment_policy?
    can_change_to_closed? if deployment_policy_changed_to 'closed'
    can_change_to_opened? if deployment_policy_changed_to 'opened'
  end

  def can_change_to_closed?
    request_ids = related_request_ids_in_states ENV_TO_CLOSED
    errors.add :deployment_policy, "couldn't be changed. Request(s) with ID #{request_ids.to_s} in
                                  #{ENV_TO_CLOSED.to_s.humanize} states contain(s) this environment" if request_ids.any?
  end

  def can_change_to_opened?
    request_ids = self.request_ids_with_active_dw_in_states ENV_TO_OPENED
    errors.add :deployment_policy, "couldn't be changed. Request(s) with ID #{request_ids.to_s} contain(s) this
                                    environment with deployment windows that haven't passed yet" if request_ids.any?
  end

  def validate_deactivate
    if self.active_changed? && !self.active && !can_deactivate?
      if self.default?
        errors.add :base, I18n.t('environment.validations.deactivate_default')
      else
        errors.add :base, I18n.t('environment.validations.deactivate_in_use')
      end
    end
  end

  def used?
    apps.any? || deployment_window_events.any?
  end

  def can_deactivate?
    !self.default? && !used?
  end

  def can_remove_server_association?( server_id )
    find_references_with_server(server_id).none?
  end

  protected

  def set_server_group_ids
    return if @server_group_ids.nil? #if no new server group ids
    del_ids = self.server_group_ids - @server_group_ids
    ins_ids = @server_group_ids - self.server_group_ids
    EnvironmentServerGroup.scoped.extending(QueryHelper::WhereIn).where(environment_id: self.id).where_in(:server_group_id, del_ids).delete_all if del_ids.present?
    EnvironmentServerGroup.transaction do
      ins_ids.each { |s_id| self.environment_server_groups.create(server_group_id: s_id) }
    end
  end

  def validate_disassociated_server_ids
    unless @server_ids.nil?
      del_ids = self.server_ids - @server_ids
      del_ids.each { | server_id | validate_disassociated_servers server_id  }
    end
  end

  def validate_disassociated_servers( server_id )
    errors.add :base, I18n.t('environment.validations.server_referenced') unless can_remove_server_association?(server_id)
  end


  def find_references_with_server( server_id )
    references.where(server_id: server_id)
  end


  def set_server_ids
    return if @server_ids.nil? #if no new server ids
    del_ids = self.server_ids - @server_ids
    ins_ids = @server_ids - self.server_ids
    EnvironmentServer.scoped.extending(QueryHelper::WhereIn).where(environment_id: self.id).where_in(:server_id, del_ids).delete_all if del_ids.present?
    EnvironmentServer.transaction do
      ins_ids.each { |s_id| self.environment_servers.create(server_id: s_id) }
    end
  end

  def set_default_server
    if @default_server_set
      self.default_environment_server.update_attribute(:default_server, false) if self.default_environment_server

      if new_default_server = self.environment_servers.find_by_server_id(@default_server_id)
        new_default_server.update_attribute(:default_server, true)
      elsif self.environment_servers.any?
        self.environment_servers.first.update_attribute(:default_server, true)
      end
    end
  end

  def remove_deployment_window_events
    self.deployment_window_events.not_passed.destroy_all
  end

end
