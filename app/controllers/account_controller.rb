################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
require 'calendar/base'

class AccountController < ApplicationController
  before_filter :set_script_filter_session, :only => [:automation_scripts]

  include ControllerSearch
  include AlphabeticalPaginator

  def settings
    unless can?(:view, GlobalSettings.new)
      redirect_to calendar_preferences_path
    end
  end

  def statistics
    authorize! :view, :statistics
  end

  def update_settings
    authorize_updating_settings!

    attr_hash = params[:GlobalSettings]
    settings_instance = GlobalSettings.instance
    if !settings_instance.update_attributes attr_hash
      @settings = settings_instance
      show_validation_errors 'settings', :div => 'error_messages'
    else
      set_auth_session(settings_instance)
      flash[:success] = I18n.t(:'settings.updated')
      ajax_redirect (params[:redirect_path] || settings_path)
    end
  end

  def system
  end

  def calendar_preferences
    authorize! :manage_calendar_preferences, GlobalSettings.new
    @calendar_fields = Calendar::FIELDS
  end

  def bladelogic
    if GlobalSettings.bladelogic_enabled?
      authorize! :list, :automation
      @keyword = params[:key]
      @per_page = 30
      @scripts = BladelogicScript.order('bladelogic_scripts.name asc')
      @scripts = @scripts.filter_by_name(@keyword) if @keyword.present?
      @total_records = @scripts.length
      flash.now[:error] = "No Bladelogic Script found" if @scripts.blank?
      @script_type = "bmc blade_logic"
      @scripts = alphabetical_paginator @per_page, @scripts
      render :partial => 'shared_scripts/bladelogic/list', :locals => {:scripts => @scripts, :path => bladelogic_path, :script => "bmc blade_logic"} if request.xhr?
    else
      flash.now[:error] = "Bladelogic Automation is disabled"
    end
  end

  def capistrano
    if GlobalSettings.capistrano_enabled?
      @keyword = params[:key]
      @per_page = 30
      @scripts = CapistranoScript.order('scripts.name asc')
      @scripts = @scripts.name_like(@keyword) if @keyword.present?
      @total_records = @scripts.length
      flash.now[:error] = "No Capistrano Script found" if @scripts.blank?
      @script_type = "ssh"
      @scripts = alphabetical_paginator @per_page, @scripts
    else
      flash.now[:error] = "SSH Automation is disabled"
    end
  end

  def hudson
    if GlobalSettings.hudson_enabled?
      @keyword = params[:key]
      @per_page = 30
      @scripts = HudsonScript.order('scripts.name asc')
      @scripts = @scripts.name_like(@keyword) if @keyword.present?
      @total_records = @scripts.length
      flash.now[:error] = "No Hudson Script found" if @scripts.blank?
      @script_type = "hudson"
      @scripts = alphabetical_paginator @per_page, @scripts
    else
      flash.now[:error] = "Hudson Automation is disabled"
    end
  end

  def automation_scripts
    if GlobalSettings.automation_enabled?
      authorize! :list, :automation
      @open_filter = session[:open_script_filter]
      if params[:clear_filter] == '1'
        reset_script_filter_session
      end
      @keyword = params[:key]
      @per_page = 30
      if @filters.nil?
        @scripts = Script.unarchived.visible_in_index.sorted 
      else
        @scripts = Script.unarchived.visible_in_index.filter_automation_script(@filters)
      end
      
      @scripts_archived = Script.archived.sorted if @filters.nil?
      @scripts_archived = Script.archived.filter_automation_script(@filters) unless @filters.nil?
      if current_user.admin?
        @scripts = @scripts.search_by_ci("name", @keyword).sorted if @keyword.present?
        @scripts_archived = @scripts_archived.search_by_ci("name", @keyword).sorted if @keyword.present?
      else
        @scripts = @scripts.search_by_ci("name", @keyword) if @keyword.present?
        @scripts = @scripts.sorted unless current_user.admin
        @scripts_archived = @scripts_archived.search_by_ci("name", @keyword) if @keyword.present?
        @scripts_archived = @scripts_archived.visible.sorted unless current_user.admin
      end
      @total_records = @scripts.length
      @total_archived = @scripts_archived.length
      flash.now[:error] = "No Script found" if @scripts.blank? && @scripts_archived.blank?
      @scripts = alphabetical_paginator @per_page, @scripts
      render :partial => "shared_scripts/list", :locals => {:scripts => @scripts, :path => automation_scripts_path, :script => "scripts", :resource_automation => false}, :layout => false if request.xhr?
    else
      flash.now[:error] = "Automation is disabled"
    end
  end

  def automation_monitor
    authorize! :view, :automation_monitor

    @per_page = 30
    @job_runs = JobRun.completed_in_last("week")
    @total_records = @job_runs.length
    flash.now[:error] = "No Job Runs found." if @job_runs.blank?
    @page = params[:page] || 1
    @job_runs = paginate_records(@job_runs, params, @per_page)
    @delay_jobs = AutomationQueueData.all
  end

  def quick_automation
    @script = CapistranoScript.first
    render :layout => false
  end

  def reset_script_filter_session
    @filters = session[:script_filter_session] = nil
  end


  def toggle_script_filter
    if params[:open_filter] == 'true'
      session[:open_script_filter] = true
    else
      session[:open_script_filter] = false
    end
    render :nothing => true
  end

  private

  def set_auth_session(setting_instance)
    case setting_instance[:authentication_mode].to_s
      when "0"
        session[:auth_method] = "Login"
        return
      when "1"
        session[:auth_method] = "ldap"
        return
      when "2"
        session[:auth_method] = "CAS"
        return
    end
  end

  def is_admin?
    unless current_user.admin?
      # flash[:error] = "Access Denied ! You do not have adequate rights to manage General settings"
      flash[:error] = I18n.t(:'activerecord.notices.no_permissions', action: 'manage', model: 'General settings')
      access_denied!
    end
  end

  def set_script_filter_session
    if params[:filters].present?
      session[:script_filter_session] ||= HashWithIndifferentAccess.new
      @filters = session[:script_filter_session] = params[:filters]
    else
      @filters = session[:script_filter_session]
      @filters
    end
  end

  def authorize_updating_settings!
    if managing_calendar?
      authorize! :manage_calendar_preferences, GlobalSettings.new
    else
      authorize! :edit, GlobalSettings.new
    end
  end

  def managing_calendar?
    params[:GlobalSettings][:calendar_preferences].present?
  end

end
