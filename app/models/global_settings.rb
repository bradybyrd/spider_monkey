require 'open-uri'

class GlobalSettings < ActiveRecord::Base

  # TODO: RJ: Rails 3: Acts as singleton gem causing problems. Disabled temporarily
  #acts_as_singleton

  AUTHENTICATION_MODE_DEFAULT = 0 unless const_defined?(:AUTHENTICATION_MODE_DEFAULT)
  AUTHENTICATION_MODE_LDAP = 1 unless const_defined?(:AUTHENTICATION_MODE_LDAP)
  AUTHENTICATION_MODE_CAS = 2 unless const_defined?(:AUTHENTICATION_MODE_CAS)
  AUTHENTICATION_MODE_SSO = 3 unless const_defined?(:AUTHENTICATION_MODE_SSO) # Legacy setting for Novartis
  HUMANIZED_COLLUMNS = {company_name: 'Instance Name'} unless const_defined?(:HUMANIZED_COLLUMNS)

  LDAP_AUTH_TYPES = %w(Directory Groups) unless const_defined?(:LDAP_AUTH_TYPES)
  LDAP_AUTH_TYPE_DIRECTORY = 0 unless const_defined?(:LDAP_AUTH_TYPE_DIRECTORY)
  LDAP_AUTH_TYPE_GROUPS = 1 unless const_defined?(:LDAP_AUTH_TYPE_GROUPS)
  LDAP_AUTH_DEFAULT_TYPE = LDAP_AUTH_TYPE_DIRECTORY unless const_defined?(:LDAP_AUTH_DEFAULT_TYPE)

  SESSION_TIMEOUT_VALUES =  [
                              ['15 minutes', 15.minutes],
                              ['30 minutes', 30.minutes],
                              ['1 hour', 1.hour],
                              ['2 hours', 2.hours],
                              ['4 hours', 4.hours],
                              ['6 hours', 6.hours],
                              ['8 hours', 8.hours],
                              ['10 hours', 10.hours]
                            ] unless const_defined?(:SESSION_TIMEOUT_VALUES)

  attr_accessible :company_name, :default_date_format, :timezone, :one_click_completion, :calendar_preferences,
                  :limit_versions, :capistrano_enabled, :bladelogic_enabled, :hudson_enabled,
                  :authentication_mode, :forgot_password, :cas_server,
                  :ldap_host, :ldap_port, :ldap_component, :ldap_bind_base, :ldap_bind_user, :ldap_bind_password,
                  :ldap_account_attribute, :ldap_first_name_attribute, :ldap_last_name_attribute, :ldap_mail_attribute, :ldap_auth_type,
                  :bladelogic_ip_address, :bladelogic_username, :bladelogic_password, :bladelogic_rolename, :bladelogic_profile,
                  :automation_enabled, :commit_on_completion, :base_url, :session_timeout, :messaging_enabled

  @mutex = Mutex.new
  @update_settings = Mutex.new

  # Workaround for making this thing work with Oracle enhanced adapter
  # The acts_as_singleton gem will block any methods that contain the "create" keyword
  if OracleAdapter
    public_class_method :custom_create_method
  end

  before_save :clear_unnecessary_values
  validates :base_request_number,
            presence: true
  validate :validate_authentication_settings
  validates :company_name,
            presence: true,
            length: {maximum: 60, allow_nil: true, allow_blank: true}
  validates :ldap_host,
            length: {maximum: 100, allow_nil: true, allow_blank: true}
  validates :ldap_component,
            length: {maximum: 255, allow_nil: true, allow_blank: true}
  validates :ldap_port,
            length: {maximum: 10, allow_nil: true, allow_blank: true}
  validates :cas_server,
            length: {maximum: 100, allow_nil: true, allow_blank: true},
            format: {with: URI::regexp, allow_nil: true, allow_blank: true}
  validate :cas_server_url
  after_initialize :initialize_data

  def initialize_data
    if new_record?
      self.base_request_number = 1000
      self.default_date_format = '%m/%d/%Y %I:%M %p'
      self.timezone = 'Eastern Time (US & Canada)'
      self.forgot_password = true
      self.company_name = 'BRPM Instance'
    end
  end

  private
  def validate_authentication_settings
    if authentication_mode == AUTHENTICATION_MODE_LDAP
      errors[:base] << 'LDAP Host cannot be blank' if ldap_host.blank?
      errors[:base] << 'LDAP Search String cannot be blank' if ldap_component.blank?
    end
    if authentication_mode == AUTHENTICATION_MODE_CAS
      errors[:base] << 'CAS Server cannot be blank' if cas_server.blank?
    end
  end

  private
  def cas_server_url
    if cas_server.present?
      response = open(cas_server, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE) rescue false
      errors[:base] << " #{cas_server} is invalid. Connectivity could be not set. Are you sure this URL is valid?" unless response
    end
  end

  private
  def clear_ldap_configuration
    self.ldap_host = ''
    self.ldap_port = ''
    self.ldap_component = ''
  end

  private
  def clear_cas_configuration
    self.cas_server = ''
  end

  private
  def clear_unnecessary_values
    case authentication_mode
    when nil, AUTHENTICATION_MODE_DEFAULT, AUTHENTICATION_MODE_SSO
      clear_ldap_configuration
      clear_cas_configuration
      return
    when AUTHENTICATION_MODE_LDAP
      clear_cas_configuration
      return
    when AUTHENTICATION_MODE_CAS
      clear_ldap_configuration
      return
    end
  end

  def self.human_attribute_name(attribute, options={})
    HUMANIZED_COLLUMNS[attribute.to_sym] || super
  end

  def method_missing(method, *args)
    if method.to_s.ends_with?('?')
      if respond_to?(method.to_s[0...-1].to_sym)
        method.to_s[0...-1].to_sym
      else
        super
      end
    else
      super
    end
  end

  class << self

    def instance
      @mutex.synchronize {
        #Reload object in case there were errors during previous save operation
        if @local_instance.nil? || !@local_instance.errors.empty?
          @local_instance = first || create
        end
      }
      @local_instance
    end

    def clear_local_instance
      @mutex.synchronize {
        @local_instance = nil
      }
    end

    def [] (name)
      instance[name]
    end

    def []=(name, new_value)
      @update_settings.synchronize {
        instance[name] = new_value
        instance.save!
      }
    end

    def default_authentication_enabled?
      instance.authentication_mode == nil || instance.authentication_mode == AUTHENTICATION_MODE_DEFAULT
    end

    def ldap_enabled?
      instance.authentication_mode == AUTHENTICATION_MODE_LDAP
    end

    def cas_enabled?
      instance.authentication_mode == AUTHENTICATION_MODE_CAS
    end

    def sso_enabled?
      instance.authentication_mode == AUTHENTICATION_MODE_SSO
    end

    def bladelogic_ready?
      [:bladelogic_ip_address, :bladelogic_username, :bladelogic_password, :bladelogic_rolename, :bladelogic_profile].each do |s|
        return false if instance[s].nil?
      end
      instance[:bladelogic_enabled] == true
    end

    def automation_available?
      automation_enabled?
    end

    # def automation_enabled?
    #   bladelogic_enabled? || capistrano_enabled? || hudson_enabled?
    # end

    def bladelogic_available?
      bladelogic_ready? && BladelogicScript.count > 0
    end

    # def hudson_available?
    #   instance[:hudson_enabled] == true && HudsonScript.count > 0
    # end

    # def capistrano_available?
    #   instance[:capistrano_enabled] == true && CapistranoScript.count > 0
    # end

    def human_date_format
      DEFAULT_DATE_FORMATS_FOR_SELECT.select { |f| f.last == instance[:default_date_format] }.first.first.match(/\S+/)[0]
    end

    def is_WickedPdf_installed?
      exe_path ||= WickedPdf.config[:exe_path] unless WickedPdf.config.empty?
      return false if exe_path.empty?
      return false unless File.exists?(exe_path)
      return false unless File.executable?(exe_path)
      true
   end

    def method_missing(method, *args)
      if method.to_s.ends_with?('?')
        instance[method.to_s[0...-1]]
      else
        super
      end
    end
  end

end

