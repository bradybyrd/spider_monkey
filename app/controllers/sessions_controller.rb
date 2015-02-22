################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

class SessionsController < ApplicationController

  skip_before_filter :authenticate_user!, :verify_user_login_status, :sign_out_inactive_user
  before_filter CASClient::Frameworks::Rails::GatewayFilter, only: [:new] if GlobalSettings.cas_enabled?
  after_filter :check_permissions, only: :create
  include SessionsHelper

  def new
    # request.headers["REMOTE_USER"] = "admin" # << Enable for SSO testing
    if GlobalSettings.cas_enabled? && !(params[:brpmadmin] == 'true') && !flash[:error].present?
      cas_authentication
    else
      session[:auth_method] = 'Login' unless request_sso_enabled?
      request_sso_enabled? ? sso_authentication : redirect_to_dashboard_or_login
    end
    session['last_update_check'] = Time.now
  end

  def create
    if GlobalSettings['base_url'].blank? || GlobalSettings['base_url'].include?('localhost') || GlobalSettings['base_url'].include?('127.0.0.1')
      GlobalSettings['base_url'] = "#{request.protocol}#{request.host_with_port}" # BJB for model access
    end
    begin
      type_of_authentication = (GlobalSettings.ldap_enabled? ? 'ldap' : 'Login')
      @user = User.find_by_login(params[resource_name]['login'])
      params[:authentication_mode] = type_of_authentication
      env['devise.allow_params_authentication'] = true
      if !user_is_root? && GlobalSettings.cas_enabled?
        login_fail('CAS authentication is enabled. Only Administrator can login using local credentials.')
      elsif resource = authenticate(resource_name, type_of_authentication)
        sign_in_and_redirect_user(resource, resource_name)
      elsif [:custom, :redirect].include?(warden.result)
        throw :warden, scope: resource_name
      else
        sign_out_all_scopes
        login_fail('Unable to authenticate you with the information you provided.  Please re-enter your login and password.')
      end
    rescue Net::LDAP::LdapError
      sign_out_all_scopes
      login_fail('LDAP settings seems to be invalid. Please contact Administrator for more details.')
    end
    session[:auth_method] = params[:authentication_mode].present? ? params[:authentication_mode] : 'Login'
    session[:login_time_auth_method] = session[:auth_method]
  end

  def destroy
    @sso_enabled = session[:sso_enabled]
    @logged_in_through_cas = session[:logged_in_through_cas] == 'true'
    @enabled_cas_in_this_session = ((session[:login_time_auth_method] != 'CAS') && (session[:auth_method] == 'CAS') && (GlobalSettings.cas_enabled?))
    # nullify the last_response_at so we know they are gone
    if signed_in?
      current_user.update_attributes(last_response_at: nil)
      PermissionMap.instance.clean(current_user)
    end

    #sign_out_all_scopes
    sign_out(:user)
    if @enabled_cas_in_this_session
      flash.now[:error] = 'Restart Your server to take effect the changes for CAS server.'
    else
      flash.now[:success] = 'You have been logged out.'
    end
    if GlobalSettings.cas_enabled? && @logged_in_through_cas
      cas_signout
    else
      render action: 'new'
    end
    #render :action => 'new' unless ((GlobalSettings.cas_enabled? && @cas_url.present?) || @sso_enabled)
    #render :action => 'new'
  end

  def account_is_inactive
    sign_out_all_scopes
    flash[:error] = 'Your account login is disabled or access to the system is blocked. Please contact Administrator for more details.'
    redirect_to login_path
  end

  def cas_signout
    begin
      CASClient::Frameworks::Rails::Filter.logout(self)
    rescue
      flash.now[:error] = 'Restart Your server to take effect the changes for CAS server.'
      render action: 'new'
    end
  end

  def bad_route
    @bad_url = request.url
    render_404
  end

  # ========================= Protected Routines ============================
  protected

  def sign_in_and_redirect_user(resource, resource_name)
    if resource.active? && (resource.first_time_login? or resource.is_reset_password?)
      scope = Devise::Mapping.find_scope!(resource_name)
      sign_in(scope, resource.reload)
      if params[:authentication_mode] == 'ldap' && valid_attr_for?(resource)
        resource.first_time_login = false
        resource.save(validate: false)
        redirect_to root_path
      else
        resource.first_time_login? ? (redirect_to new_security_question_path) && return : (redirect_to change_password_users_path) && return
        flash[:success] = 'Logged in successfully - A new account has been created for you.'
      end
    else
      if resource.active?
        resource.update_attribute(:last_response_at, Time.now)
        sign_in_and_redirect(resource_name, resource)
        flash[:success] = 'Logged in successfully'
      else
        account_is_inactive
      end
    end
  end

  def cas_login
    if GlobalSettings.cas_enabled? and params['authentication'].nil?
      logger.info 'SS__ Setting filter'
      CASClient::Frameworks::Rails::Filter
    end
  end

  def cas_set_login_url
    # The login URL must be set in the controller for a full URL.
    # Setting in the helper or the view generate an action only url that will keep the
    # user in the CAS Server.
    @cas_login_url = CASClient::Frameworks::Rails::Filter.login_url(self) rescue ''
    session[:cas_url] = @cas_login_url
    @cas_user = User.find_by_login(session[:cas_user])
  end

  def sso_authentication
    @user = User.sso_authentication(request.headers)
    @user.class == User ? sign_in(:user, @user) : (render action: 'new' && return)
    session[:auth_method] = 'SSO'
    if @user.active?
      if valid_attr_for?(@user)
        @user.first_time_login = false
        @user.save(validate: false)
        sign_in_and_redirect(resource_name, @user)
      else
        redirect_to new_security_question_path
      end
    else
      account_is_inactive && return
    end
  end

  def cas_authentication
    cas_set_login_url
    if session[:cas_user] && !signed_in?
      session[:auth_method] = 'CAS'
      session[:logged_in_through_cas] = 'true'
      if @cas_user.blank?
        user = User.cas_authentication(session[:cas_user])
        sign_in_and_redirect(:user, user) if user.present?
      elsif @cas_user.active?
        if valid_attr_for?(@cas_user)
          @cas_user.first_time_login = false
          @cas_user.save(validate: false)
          current_user = @cas_user
          sign_in_and_redirect(:user, @cas_user)
        else
          redirect_to new_security_question_path
        end
      else
        cas_error
        account_is_inactive && return
      end
    elsif session[:cas_url].blank?
      flash.now[:error] = 'Restart Your server to take effect the changes for CAS server.'
      render action: 'new'
    else
      redirect_to @cas_login_url
    end
  end

  def valid_attr_for?(user)
    user.first_name.present? && user.last_name.present? && user.email.present?
  end

  def cas_error
    params[:cas_login_error] = 'true'
  end

  private

  def check_permissions
    flash[:notice] = I18n.t('session.create.no_main_tabs_selected') unless MainTabs.selected_any?(current_user)
  end

  def redirect_to_dashboard_or_login
    user_signed_in? && current_user.active? ? redirect_to(root_path) : render('new')
  end

  def login_fail(error_message)
    reset_session
    flash[:error] = error_message
    redirect_to login_path
  end

end
