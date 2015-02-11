################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

module SessionsHelper

  def choose_form
    params[:authentication] == 'ldap' ? 'form_ldap' : 'form_basic'
  end

  def link_to_forgot_password
    link_to 'Forgot password?', forgot_password_path, class: 'password' if GlobalSettings.forgot_password?
  end

  def link_to_forgot_userid
    link_to 'Forgot username?', forgot_userid_path, class: 'userid' if GlobalSettings.forgot_password?
  end

  def cas_login_error?
    params[:cas_login_error] == 'true'
  end

  def resource_name
    :user
  end
 
  def resource
    @resource ||= User.new
  end
 
  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def signed_in_root_path(user)
    MainTabs.root_path(user)
  end

end
