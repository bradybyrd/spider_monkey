################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

require 'net-ldap'
require 'xmlsimple'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  # :token_authenticatable, :lockable, :timeoutable, :confirmable and :activatable
  devise :database_authenticatable, :registerable, :encryptable, :timeoutable,
         :recoverable, :trackable, :validatable, authentication_keys: [:login]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :first_name, :last_name, :email, :password,
                  :password_confirmation, :contact_number, :time_zone,
                  :first_day_on_calendar, :list_order, :remember_me,
                  :tab_name, :commit, :reset_password_token, :last_response_at,
                  :app_ids, :login, :email, :contact_number, :password,
                  :password_confirmation, :first_name, :last_name, :group_ids, :location,
                  :employment_type, :system_user, :max_allocation, :group, :group_ids,
                  :time_zone, :list_order, :team_ids, :app_roles, :env_roles, :app_env_roles,
                  :visible_apps, :calendar_preferences, :current_password,
                  :calendar_preferences, :admin, :root, :global_access, :remember_me,
                  :active, :group_ids, :first_day_on_calendar


  API_SALT = 'dd78b17948f7106364fbb01e08b1659433'

  # ideally, a system setting would be created to manage this, leaving
  # this default constant as a backup but a value from global settings as the
  # primary value for when users are no longer to show in the online user
  # display on the dashboard.  Note: session expiration is handled by devise
  # and defaults to 30 minutes.
  DEFAULT_MINUTES_UNTIL_OFFLINE = 10

  include SoftDelete
  include AllocationHelpers
  include QueryHelper
  include ActiveRecordAssociationsExtensions

  concerned_with :visibility
  concerned_with :user_named_scopes

  Authentications = %w(basic ldap)

  # TODO: Allow user to set attribute name
  LDAP_DEFAULT_ATTRIBUTE_EMAIL        = 'mail'
  LDAP_DEFAULT_ATTRIBUTE_FIRST_NAME   = 'displayName'
  LDAP_DEFAULT_ATTRIBUTE_LAST_NAME    = 'sn'
  LDAP_DEFAULT_ACCOUNT_ATTRIBUTE_NAME = 'cn'
  LDAP_SM_ACCOUNT_ATTRIBUTE_NAME      = 'sAMAccountName'

  attr_accessor :password, :app_roles, :env_roles, :app_env_roles,
                :visible_apps, :authenticated_in_rpm_db, :notification_failed,
                :current_password

  serialize :calendar_preferences, Array

  has_and_belongs_to_many :managed_groups, join_table: 'group_management', foreign_key: 'manager_id', class_name: 'Group'

  has_many :workstreams, foreign_key: :resource_id, dependent: :destroy, include: :resource_allocations
  has_many :activities, through: :workstreams
  has_many :resource_allocations, through: :workstreams

  
  has_many :logs, class_name: 'ActivityLog', order: 'created_at DESC, usec_created_at DESC', dependent: :destroy
  has_many :notes, dependent: :destroy

  has_many :managed_activities, class_name: 'Activity', foreign_key: 'manager_id'

  has_many :calendar_reports
  has_one  :default_tab, dependent: :destroy
  has_many :calendar_reports

  has_many :user_groups, dependent: :destroy
  has_many :groups, through: :user_groups, after_remove: :prevent_removing_non_valid_group

  has_many :teams,                  through: :groups, order: 'teams.name ASC'
  has_many :roles,                  through: :groups, uniq: true
  has_many :permissions,            through: :groups # TODO: permissions on envs should be considered


  has_many :activity_deliverables, foreign_key: 'deployment_contact_id'

  has_many :integration_csvs, dependent: :nullify

  has_one :security_answer

  has_many :scheduled_jobs, foreign_key: :owner_id, dependent: :destroy

  validates :first_name,
            presence: true,
            length: {maximum: 255}
  validates :last_name,
            presence: true,
            length: {maximum: 255}
  # Modified RegEx to allow Special Characters - SN
  validates :password,
            format: {with: /^(?=.*\d)(?=.*[a-z]).{6,40}$/,
                     message: 'must contain at least one letter and at least one number',
                     if: :password_required?},
            confirmation: {unless: :password_required?},
            presence: {if: :password_needed?}
  validates :login,
            length: {within: 3..40, if: :system_user?},
            uniqueness: {case_sensitive: false}
  validates :email,
            length: {within: 3..100, if: :system_user?}
  validates :contact_number,
            length: {maximum: 255}
  validates :max_allocation,
            inclusion: {in: 0..100, message: 'must be between 0 and 100.'}
  validates :employment_type,
            inclusion: {in: %w[permanent contractor], allow_blank: true}
  validates_associated :groups

  # FIXME: This should use the custom validation below on live data and not call a constant which
  # needs to be reloaded -- I patched this by adding it to an after save hook but the whole system
  # of constants is brittle
  # validates_inclusion_of    :location,        in: Locations,       allow_blank: true

  # custom validation added because class base approach relied on controller call to reload constants
  # which will not allow list items to be added through rest or testing

  # merge conflict with another custom validation approach -- picked mine because it assigned errors to the field
  # which is something helpful for validation and accurate messages back to the REST clients
  validate :valid_location
  validate :current_password_valid, unless: Proc.new { |u| u.current_password.nil? }
  validate :new_password_validation

  after_create :send_welcome_email
  before_save :encrypt_password, :ensure_api_key, :set_reset_password_token, :ensure_default_group
  after_update :send_notification_email
  after_save :update_assigned_apps
  before_validation :prevent_update, on: :update, unless: :active_during_update?

  accepts_nested_attributes_for :security_answer

  acts_as_audited protect: false

  scope :admins, lambda { where(id: UserGroup.root_user_ids) }

  def ability
    @ability ||= Ability.new(self)
  end
  delegate :can?, :cannot?, to: :ability

  def ensure_default_group
    if self.group_ids.blank?
      default_group = Group.default_group
      self.groups << default_group if default_group
    end
  end

  def in_root_group?
    !(Group.root_groups.map(&:id) & self.group_ids).empty?
  end

  def states
    DeploymentWindow::Series.scoped.select(:state).group(:state).pluck(:state)
  end

  def current_password_valid
    unless authenticated?(current_password)
      errors.add(:base,'Old password doesn\'t match with password you provided.')
    end
  end

  # while changing the user password, new password should not match old password.
  # This equality is checked using "authenticated?" function because current_password is not
  # available all the time, so its encryption is used to check the equality.
  def new_password_validation
    if authenticated?(password)
      errors.add(:base,'New password should not match old password.')
    end
  end

  # the original validation for location loaded the current database state for the location
  # list into a constant, so later updates to the location would not register
  def valid_location
    if self.location
      valid_locations = List.get_list_items('Locations').sort
      unless valid_locations.include?(location)
        errors.add(:location, "Location not included in list: #{valid_locations.to_sentence}.")
      end
    end
  end

  def environments_with_roles
    if admin?
      Environment.scoped
    else
      environments_without_roles
    end
  end
  alias_method_chain :environments, :roles

  class << self

    def current_user
      Thread.current[:user]
    end

    def current_user=(user)
      Thread.current[:user] = user
    end

    def find_first_by_auth_conditions(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        where(conditions).where(['lower(login) = :value OR lower(email) = :value', { value: login.downcase }]).first
      else
        where(conditions).first
      end
    end

    def ldap_authentication(login, password)
      ldap = Net::LDAP.new
      ldap.host = GlobalSettings[:ldap_host]
      ldap.port = GlobalSettings[:ldap_port]
      ldap_dc = GlobalSettings[:ldap_component]

      ldap_first_name_attribute = GlobalSettings[:ldap_first_name_attribute].blank? ? LDAP_DEFAULT_ATTRIBUTE_FIRST_NAME : GlobalSettings[:ldap_first_name_attribute]
      ldap_last_name_attribute  = GlobalSettings[:ldap_last_name_attribute].blank? ? LDAP_DEFAULT_ATTRIBUTE_LAST_NAME : GlobalSettings[:ldap_last_name_attribute]
      ldap_mail_attribute       = GlobalSettings[:ldap_mail_attribute].blank? ? LDAP_DEFAULT_ATTRIBUTE_EMAIL : GlobalSettings[:ldap_mail_attribute]

      if ldap_dc.include?('ActiveDirectoryDomain=')
        return nil if password.blank?
        default_domain = ldap_dc.gsub('ActiveDirectoryDomain=', '').strip
        domain_login = login.include?("\\") ? login : "#{default_domain}\\#{login}"
        login = login.split("\\")[1] if login.include?("\\")
        ldap.auth(domain_login, password)
      elsif ldap_dc.include?('CustomAuthenticationScript=')
        user = custom_authentication(login, password)
        return user
      else
        return nil if password.blank?
        ldap_bind_base = GlobalSettings[:ldap_bind_base]
        ldap_account_attribute = GlobalSettings[:ldap_account_attribute]
        ldap_auth_type = GlobalSettings[:ldap_auth_type]
        # ldap.auth works only with displayName and cn as login
        # where with displayName syntax is ldap.auth(<login>, password)
        # and for cn: ldap.auth("cn=<login>,OU=some_ou_name,dc=some_dc,dc=some_other_dc", password)
        # ldap.auth does not work with sAMAccountName at all in anonymous connections
        # it means ldap.bind will return false even with correct sAMAccountName value
        ldap_account_attribute = ldap_account_attribute.blank? ? LDAP_DEFAULT_ACCOUNT_ATTRIBUTE_NAME : ldap_account_attribute
        base = ldap_auth_type == GlobalSettings::LDAP_AUTH_TYPE_GROUPS ? ldap_bind_base : ldap_dc
        domain_login = ldap_account_attribute == LDAP_DEFAULT_ACCOUNT_ATTRIBUTE_NAME ? "#{ldap_account_attribute}=#{login},#{base}" : login
        ldap.auth(domain_login, password)
      end
      begin
        entries = []
        if get_ldap_entries(login, password, ldap, entries)
          user_login = login.gsub(/.*\\/,'')
          u = self.where(['lower(login)=lower(?)', user_login]).first
          if u.blank?
            attrs = {}
            if entries.length> 0 && dn = entries.first
              attrs['email']       = dn[ldap_mail_attribute].first
              attrs['first_name']  = dn[ldap_first_name_attribute].first
              attrs['last_name']   = dn[ldap_last_name_attribute].first
            end
            attrs['login']       = user_login
            logger.info "SS__ ldap: create account: #{user_login}"
            u = create_account(attrs)
          else
            u
          end
        else
          logger.info "SS__ ldap failed: #{ldap.get_operation_result}\nLogin: #{domain_login}"
        end
      rescue Net::LDAP::LdapError
        logger.error "SS__ ldap: no connection to server \nPARAMS: Host:#{ldap.host}, DC: #{ldap_dc}, Login: #{domain_login}, Password: <private>"
        u = nil
      end
      u.blank? ? nil : u
    end

    def get_ldap_entries(login, password, ldap, entries)
      user_login = login.gsub(/.*\\/,'')
      ldap_host = GlobalSettings[:ldap_host]
      ldap_port = GlobalSettings[:ldap_port]
      ldap_auth_type = GlobalSettings[:ldap_auth_type]
      ldap_dc = GlobalSettings[:ldap_component]
      ldap_bind_base = GlobalSettings[:ldap_bind_base]
      ldap_bind_user = GlobalSettings[:ldap_bind_user]
      ldap_bind_password = GlobalSettings[:ldap_bind_password]
      ldap_account_attribute = GlobalSettings[:ldap_account_attribute]
      ldap_account_attribute = ldap_account_attribute.blank? ? LDAP_DEFAULT_ACCOUNT_ATTRIBUTE_NAME : ldap_account_attribute

      base = ldap_dc

      filter = Net::LDAP::Filter.eq( 'objectClass', 'person' ) & Net::LDAP::Filter.eq( ldap_account_attribute, user_login )
      if ldap_auth_type == GlobalSettings::LDAP_AUTH_TYPE_GROUPS
        base = ldap_bind_base
        grp_filter = nil
        ldap_dc.split(';').each do |el|
          grp_filter = grp_filter.nil? ? Net::LDAP::Filter.eq('memberOf', el) : (grp_filter | Net::LDAP::Filter.eq('memberOf', el))
        end
        filter = filter & grp_filter
      end
      if ldap_bind_user.blank? || ldap_bind_password.blank?
        result = ldap.bind
        if result
          if base.include?('ActiveDirectoryDomain=')
            logger.info 'SS__ldap - AD Option'
          else
            entries = []
            ldap.search(base: base, filter: filter) do |entry|
              entries << entry
            end
            result = !entries.empty?
          end
        end
      else
        result = false
        ldap = Net::LDAP.new({
                                 host: ldap_host,
                                 port: ldap_port,
                                 auth: {
                                     method: :simple,
                                     username: ldap_bind_user,
                                     password: ldap_bind_password
                                 }
                             })
        entries ||= []
        begin
          ldap.search(base: base, filter: filter) do |entry|
            entries << entry
          end
        rescue => e
          logger.error "SS__ ldap: couldn't get user data from ldap by login #{login}.\n #{e}"
        end

        if entries.present?
          ldap_con = Net::LDAP.new({
                                       host: ldap_host,
                                       port: ldap_port,
                                   })
          ldap_con.authenticate(entries.first.dn, password)
          result = ldap_con.bind
        else
          result = false
        end
      end
      result
    end

    def sso_authentication(request_headers)
      login = request_headers['REMOTE_USER']
      user = User.find_by_login(login)
      if user.blank?
        attrs = {}
        logger.info "SS__ SSO User not found: #{login}"
        attrs['login'] = login
        user = create_account(attrs)
      end
      user
    end

    def cas_authentication(cas_user)
      if cas_user
        attrs = {}
        attrs['login'] = cas_user
        user = create_account(attrs)
      end
      user.blank? ? nil : user.reload
    end


    def custom_authentication(login, password)
      # Support for a custom script authenticator
      # called from the command line as an executable script
      # Format of return message
      # <xml>
      #   <status>success</status>
      #   <message>User logged in</message>
      #   <first_name>Frank</first_name>
      #   <last_name>Lloyd Wright<last_name>
      #   <login>flw</login>
      # </xml>

      ldap_host = GlobalSettings[:ldap_host]
      ldap_port = GlobalSettings[:ldap_port]
      ldap_dc = GlobalSettings[:ldap_component]
      wrapper_script = ldap_dc.gsub('CustomAuthenticationScript=', '').strip
      login_string = "<xml><authentication><login>#{login}</login><password>#{password}</password>"
      login_string += "<ldap><host>#{ldap_host}</host><port>#{ldap_port}</port></ldap></authentication></xml>"
      login_arg = script_authentication_encode(login_string).gsub("\n", '')
      logger.info "SS_CustomAuthenticator: #{wrapper_script} #{login_arg}"
      #  Execute the script on the Command Line
      begin
        answer = `#{wrapper_script} #{login_arg}`
      rescue => err
        logger.error "SS__ Custom Authentication Error: #{err.message}"
        return
      end
      user = nil
      if answer.present?
        logger.info "Authentication Response: #{answer}"
        hash = XmlSimple.xml_in(answer)
        result = hash['result'].first
        status = result['status'].first
        if status.strip.downcase == 'success'
          user = User.find_by_login(login)
          if user.nil?
            first_name = result['first_name'].first
            last_name = result['last_name'].first
            attrs = {}
            attrs['login'] = login
            attrs['first_name'] = first_name unless first_name.nil?
            attrs['last_name'] = last_name unless last_name.nil?
            user = create_account(attrs)
          end
        end
      end
      user
    end

    # removed password salt compatibility
    def api_key_authentication(token)
      encoded_api_key = User.encode_api_key(token) if token
      user = (find_by_api_key(encoded_api_key)) if encoded_api_key
      if user && user.admin? && user.active?
        User.current_user = user
      else
        User.current_user = nil
      end
    end

    # this does not encrypt, but does encode the api_key in the database to make it a little more obscure
    # FIXME: Securing an api_key requires encryption and a second token or certificate, not this simple obscuration
    # but the standard has not been settled in time for this release
    def encode_api_key(unencoded_api_key)
      Base64.encode64(unencoded_api_key + API_SALT)
    end

    def decode_api_key(encoded_api_key)
      Base64.decode64(encoded_api_key).gsub(API_SALT, '')
    end

    # Encrypts some data with the salt.
    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end

    # FIXME: make these named scopes
    def find_by_email_or_login(uid)
      user_by_login = find_by_login(uid)
      return user_by_login unless user_by_login.nil?
      find_by_email(uid)
    end

    # FIXME: make these named scopes
    def find_by_any(uid)
      msg = 'User not found'
      user_found = find_by_login(uid)
      return user_found unless user_found.nil?
      user_found = find_by_email(uid)
      return user_found unless user_found.nil?
      if uid.split(',').size > 1
        user_found = User.find(:first, conditions: "first_name LIKE '#{uid.split(",")[1].strip}' and last_name LIKE '#{uid.split(",")[0].strip}'")
        return user_found unless user_found.nil?
      elsif uid.split(' ').size > 1
        user_found = User.find(:first, conditions: "last_name LIKE '#{uid.split(" ")[1].strip}' and first_name LIKE '#{uid.split(" ")[0].strip}'")
        return user_found unless user_found.nil?
      else
        user_found = User.find(:all, conditions: "last_name LIKE '#{uid}'")
        cnt = user_found.count
        msg = "#{cnt} found non-unique" if cnt > 1
        return user_found.first if cnt == 1
      end
      user_found = Group.find_by_name(uid) if user_found.blank?
      return user_found if user_found.present?

      "#{uid}: #{msg}"
    end


    # when IAM authentication will fail, new user will be created with default role as user
    # when SSO authentication will fail, new user will be created with default role as user
    def create_account(attrs)
      u = User.new
      u.login = attrs['login']
      u.email = attrs['email']
      u.contact_number = attrs['contact_number']
      u.first_name = attrs['first_name']
      u.last_name = attrs['last_name']
      u.location = attrs['location'].try(:downcase)
      if attrs['password']
        u.password = attrs['password']
        u.password_confirmation = attrs['password']
      end
      u.first_time_login = true
      u.save(validate: false)
      u
    end

    # Overwrite Devise’s find_for_database_authentication method to authenticate the user using login name
    #def find_for_database_authentication(warden_conditions)
      #conditions = warden_conditions.dup
      #login = conditions.delete(:login)
      #where(conditions).where(["lower(username) = :value OR lower(email) = :value", { value: login.strip.downcase }]).first
    #end

    def locations
      List.get_list_items('Locations').sort
    end

  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, password_salt)
  end

  def authenticated?(password)
    encrypted_password == encrypt(password)
  end

  # override remember expired to always return true -- timeoutable must rule!
  def remember_expired?
    true
  end

  # override to allow time outs and block and remember code
  def remember_token?
    false #remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me(duration = 24)
    #    remember_me_for 2.weeks
    remember_me_for duration.to_i.hours
  end

  def remember_me_for(time)
    ##### BJB Debug #####
    time = 2.minutes
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(validate: false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(validate: false)
  end

  def name
    "#{last_name}, #{first_name}"
  end

  def to_label
    "#{first_name} #{last_name}".blank? ? login : "#{first_name} #{last_name}"
  end

  def name_for_index
    self.type == 'PlaceholderResource' ? "Placeholder-#{id.to_s}" : "#{last_name}, #{first_name}"
    # type is a reserved word and throws a deprecation -- defect will be logged and fixed
    #self.last_name + self.first_name == "" ? "Placeholder-#{id.to_s}" : "#{last_name}, #{first_name}"
  end

  def name_for_index_with_contact
    if !self.contact_number.nil? && !self.contact_number.empty?
      self.type == 'PlaceholderResource' ? "Placeholder-#{id.to_s}" : "#{last_name}, #{first_name} (#{contact_number})"
    else
      self.type == 'PlaceholderResource' ? "Placeholder-#{id.to_s}" : "#{last_name}, #{first_name}"
    end
    # type is a reserved word and throws a deprecation -- defect will be logged and fixed
    #self.last_name + self.first_name == "" ? "Placeholder-#{id.to_s}" : "#{last_name}, #{first_name}"
  end

  def short_name
    my_short_name = []
    my_short_name << (self.last_name.blank? ? "Placeholder-#{id}" : self.last_name.strip)
    my_short_name << (self.first_name[0..0] + '.' unless self.first_name.nil? || self.first_name == '')
    my_short_name.join(', ')
  end

  def role_names
    roles.map { |role| role.name.titleize }.join(', ')
  end

  def location_name
    (location || '').upcase
  end

  def employment_type_name
    employment_type.try(:titleize)
  end

  def workstream_names
    workstreams.map { |ws| ws.name }.join(', ')
  end

  def can_edit_activity?(activity)
    #TODO: For the time being all users can edit activities. These requirements will probably change.
    true
    # can_edit_activities? || activity.manager_id == id
  end

  def manages?(group)
    root? || managed_groups.include?(group)
  end

  def add_workstreams(activity_ids)
    return unless activity_ids

    activity_ids.each do |activity_id|
      workstreams.create! activity_id: activity_id unless self.activity_ids.include? activity_id
    end
  end

  def update_allocations(allocations_hash)
    return unless allocations_hash

    allocations_hash.each do |workstream_id, years_hash|
      workstream = workstreams.find_by_id workstream_id
      years_hash.each do |year, months_hash|
        months_hash.each do |month, alloc|
          workstream.try(:update_allocation, year, month, alloc)
        end
      end
    end
  end

  # BJB 3/30/10
  def fetch_managed_resource(userid)
    User.fetch_resources(self, userid)[0]
  end

  def fetch_managed_resources
    User.fetch_resources(self)
  end

  def self.fetch_resources(manager, userid = '0')
    # BJB 3/30/10 Replace with sql for both Oracle and MySQL
    i_id = userid.to_i
    if i_id > 0
      user_and = "AND u.id = #{i_id.to_s} "
    else
      user_and = ''
    end
    if manager.admin?
      find_by_sql <<-SQL
        select u.* from users u where u.id > 0 #{user_and}
        ORDER BY type, last_name, first_name
      SQL
    else
      find_by_sql <<-SQL
        select u.* from user_groups ug left join users u ON ug.user_id = u.id
        where u.active = 1 #{user_and}AND ug.group_id IN (select group_id from group_management
        where manager_id = #{manager.id}) ORDER BY type, last_name, first_name
      SQL
    end
  end

  #BJB Property Visibility and Editing

  def can_see_property?(property)
    property.is_private ? self.can?(:see_private_value, property) : true
  end

  def root?
    cache_key = [:user_root, self.id]

    Rails.cache.fetch(cache_key) do
      groups.root_groups.any?
    end
  end
  alias :admin? :root?

  def non_root?
    !root?
  end
  alias :is_not_admin? :non_root?

  def has_global_access?
    root?
  end

  def formatted_role
    return 'Deployment Coordinator' if is_only_deployment_coordinator?
    return 'Deployer' if is_only_deployer?
    return 'Requestor' if is_only_requestor?
    return 'Executor' if is_only_executor?
    'User'
  end

  def requests(show_all = true)
    return Request if admin?
    req = show_all ? Request : Request.participated_in_by(self)
    req.in_assigned_apps_of(self).accessible_to_user(self)
  end

  def involved_with_request?(request)
    request.is_associated_with_user?(self)
  end

  def is_owner_or_requestor_of?(request)
    request.owner_id == id or request.requestor_id == id
  end

  def involved_with_step?(step)
    steps.include?(step)
  end

  def group_names
    groups.select(:name).map(&:name).join(', ')
  end

  def managed_resources
    User.managed_by(self)
  end

  def placeholder_resources
    PlaceholderResource.managed_by(self)
  end

  def managed_resources_including_placeholders
    User.managed_by_including_placeholders(self)
  end

  def team_names
    teams.select(:name).map(&:name).join(', ')
  end

  def get_calendar_preferences
    calendar_preferences.blank? ? GlobalSettings[:calendar_preferences] : calendar_preferences
  end

  def update_last_response_time # This method is added to avoid callbacks
    connection.execute("UPDATE users SET last_response_at = '#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}' WHERE id = #{id}")
  end

  def resource_manager
    resource_managers.first
  end

  def resource_managers
    self.class.all(conditions: { id: groups.map(&:resource_manager_ids ).flatten })
  end

  def sr_default_role
    roles.first
  end

  def reset_password!
    success = false
    ActiveRecord::Base.transaction do
      self.password = get_new_password
      self.is_reset_password = true
      success = do_reset_password? && self.save(validate: false)
      if self.notification_failed
        success = false
        error_message = self.errors.full_messages.empty? ? self.errors.full_messages.first : 'Email not configured. Contact administrator!'
        raise ActiveRecord::Rollback, error_message
      end
    end
    success
  end

   # may be called from the API when current user is not set
   def deactivate!
    if User.current_user.try(:id) != id
      self.update_attribute(:active, false)
      return true
    else
      errors.add(:base, 'You cannot deactivate yourself.')
    end
    false
  end

  def change_password!(password = nil, password_confirmation = nil, current_password = nil)
    self.current_password = current_password
    self.password = password
    self.password_confirmation = password_confirmation
    self.is_reset_password = false
    success = self.save
    success && !self.notification_failed
  end

  # override the default getter to create api_keys for legacy users without one
  def api_key
    ensure_api_key
    api_key = User.decode_api_key(self[:api_key]) if self.in_root_group? && self.active?
    api_key || nil
  end

  # works with application controller after filter
  # that touches the user record on each request
  def online?
    last_response_at > DEFAULT_MINUTES_UNTIL_OFFLINE.minutes.ago
  end

  def timeout_in
    if GlobalSettings[:session_timeout].present?
      GlobalSettings[:session_timeout].seconds
    else
      super
    end
  end

  def query_object
    UserQuery.new(self)
  end

  protected
  def send_welcome_email
    get_admins.each do |admin|
      send_welcome_email_for_user(admin) if email_exists? && self.system_user?
    end
    send_welcome_email_for_admin unless GlobalSettings.default_authentication_enabled?
  end

  def send_welcome_email_for_admin
    Notifier.delay.user_admin_created(self, {ldap: "From ldap - #{self.login}"})
  end

  def send_welcome_email_for_user(admin)
    Notifier.delay.user_created(self, admin)
  end

  def email_exists?
    self.try(:email).present?
  end

  def get_admins
    self.admin? ? User.admins.reject{|a| a.email == self.email} : User.admins
  end

  def send_notification_email
    return unless encrypted_password_changed?
    # send the right message whether changed by hand or simply reset
    if do_reset_password?
      User.admins.each do |admin|
        self.is_reset_password ? Notifier.delay.password_reset(self,admin) : Notifier.delay.password_changed(self,admin)
      end
    else
      message = I18n.t('user.errors.base.change_password')
      self.errors[:base] << message
      log_and_set_failure_flag(Exception.new(message))
    end
  end

  def encrypt_password
    return if password.blank?
    self.password_salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record? || self.password_salt.blank?
    self.encrypted_password = encrypt(password)
  end

  def ensure_api_key
    # recreate it if it is blank or old style un-obscured
    if self[:api_key].blank? || self[:api_key].length == 40
      self.api_key = create_api_key
    end
  end

  def set_reset_password_token
    # Due to devise gem, reset_password_token is added in user model and
    # it has a unique index on it.
    # as this value and its functionality is not used in BRPM, this column
    # gets saved as NULL. In SqlServer 2008, unique index doesn't follow
    # SQL-92 standard. Hence, multiple NULL values are not allowed.

    if login.present?
      # As 'login' is a unique value for a user, the same value is assigned to
      # 'reset_password_token' field
      self.reset_password_token = self.login
    else
      # In case when login is empty (creating resource user from GUI)
      # we populate 'reset_password_token' field with some unique string
      # in current case it's date-time stamp + object id
      self.reset_password_token = DateTime.now.strftime('%F %T.%L%:z') + ' ' + self.object_id.to_s
    end
  end

  def create_api_key
    # make up a big random salt
    api_salt = ''
    64.times { api_salt << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
    # now make a hash from the current time and the pseudo random salt and finally encode it reversibly for the database
    User.encode_api_key(Digest::SHA1.hexdigest(api_salt)) # return key
  end

  def password_required?
    authenticated_in_rpm_db && system_user? && (encrypted_password.blank? || !password.blank?)
  end

  def password_needed?
    new_record? && !GlobalSettings.ldap_enabled?
  end

  def get_new_password(len=10)
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    newpass = ''
    1.upto(len) { |_| newpass << chars[rand(chars.size-1)] }
    newpass
  end

  # dry up a little bit -- error handling should be application wide
  # or at least handled the same for all notification errors in that class
  # but at least for common user notification errors we show a message
  # and try to keep on going.
  # setting the rescue level at Exception because timeout errors were getting
  # through to the capistrano_script time out handler
  def log_and_set_failure_flag(e)
    # where before the log message was lost, now it is written to the log
    logger.error "SS__ EMail Error: #{e.try(:message)}\n#{e.try(:backtrace).try(:join, "\n")}"
    self.notification_failed = true
  end

  private

  def do_reset_password?
    !password.blank? && email_exists?
  end

  def active_during_update?
    active? || active_was
  end

  def prevent_update
    errors.add(:base, I18n.t('user.edit_error'))
    false
  end

  def prevent_removing_non_valid_group(group)
    self.groups << group if group.active? && !group.valid?
  end

end
