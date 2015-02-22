################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'permissions/permission_granters'
require File.join(Rails.root, 'app', 'models', 'csv_importer')

class AppsController < ApplicationController

  OPTIONAL_EXPORT_COMPONENTS = [:servers, :req_templates, :automations, :deployment_windows]

  before_filter :can_work_with_app?, only: [:edit, :update, :show, :destroy]
  before_filter :warning_for_app_editing, only: [:create]
  include MultiplePicker

  include ControllerSoftDelete
  include AlphabeticalPaginator

  def index
    authorize! :view, :applications_tab
    @per_page = 30
    @keyword = params[:key]
    @active_applications = current_user.accessible_apps
    @inactive_applications = current_user.inactive_accessible_apps
    if @keyword.present?
      @active_applications = @active_applications.search_by_ci('name', @keyword )
      @inactive_applications = @inactive_applications.search_by_ci('name', @keyword )
    end
    @total_records = @active_applications.length
    @total_inactive_records = @inactive_applications.length
    if @inactive_applications.blank? and @active_applications.blank?
      flash.now[:error] = 'No Applications Found'
    end
    @active_applications = alphabetical_paginator(@per_page, @active_applications)
    @inactive_applications = alphabetical_paginator(@per_page, @inactive_applications, true)
    render partial: 'index', layout: false if request.xhr?
  end

  def new
    @app = App.new
    authorize! :create, @app
  end

  def show
    respond_to do |format|
      format.html do
        authorize! :edit, @app
        render template: 'apps/edit'
      end
    end
  end

  def edit
    @app = find_app
    authorize! :edit, @app
  end

  def create
    @app = App.new(params[:app])
    authorize! :create, @app

    if TeamPresenceAppValidator.new(@app).valid?
      @app.save
      flash[:notice] = I18n.t(:'activerecord.notices.created', model: I18n.t(:'table.application'))
      redirect_to edit_app_path(@app, page: params[:page], key: params[:key])
    else
      render action: 'new'
    end
  end

  def update
    @app = find_app
    authorize! :update, @app

    if @app.update_attributes(params[:app])
      #PermissionMap.instance.bulk_clean(@app.users)
      alpha_reorder if params[:alpha_sorting_update] == 'yes'
      flash[:notice] = 'Application was successfully updated.'
      redirect_to edit_app_path(@app, page: params[:page], key: params[:key])
    else
      render action: 'edit'
    end
  end

  def destroy
    @app = find_app
    authorize! :destroy, @app

    if @app.active?
      flash[:error] = 'Active applications cannot be destroyed'
    else
      @app.destroy
    end

    redirect_to apps_path(page: params[:page], key: params[:key])
  end

  def import_app
    if current_user.admin?
      @teams = Team.order(:name)
    else
      @teams = current_user.teams.uniq
    end
    render layout: false
  end

  def import
    authorize! :import, App.new
    if params[:app].nil?
      flash[:error] = I18n.t(:'app_import.file_select')
    else
      content_type = get_content_type params
      if content_type == 'xml' || content_type == 'json'
        begin
          team = Team.find(params[:team_id])
          @app = App.import(params[:app].read, current_user, team, content_type)
          if @app.errors.any?
            @app.errors.full_messages.each do |full_message|
              flash[:error] = full_message
            end
          else
            flash[:success] = I18n.t(:'app_import.import_success', app_name: @app.name)
          end
        rescue ArgumentError => e
          flash[:error] = e.message
        end
      else
        flash[:error] = I18n.t(:'app_import.format_error')
      end
    end
    redirect_to apps_path
  end

  def export_application
    @app = find_app
    render layout: false
  end

  def export
    @app = App.export(params[:id])
    authorize! :export, @app
    @app.reload
    app_presenter = V1::AppsPresenter.new(@app, nil, { export_app: true, optional_components: components_to_export })
    if params[:format] == 'JSON'
      send_data app_presenter.to_json, type: 'application/json', filename: "#{@app.name}_#{Time.now.to_i}.json"
    else
      send_data app_presenter.to_xml, type: 'text/xml', filename: "#{@app.name}_#{Time.now.to_i}.xml"
    end
  end

  def reorder_components
    @app = find_app
    authorize! :reorder, ApplicationComponent.new

    redirect_to @app if @app.a_sorting_comps
  end

  def reorder_environments
    @app = find_app
    authorize! :reorder, ApplicationEnvironment.new

    redirect_to @app if @app.a_sorting_envs
  end

  def create_default
    App.create_default
    redirect_to apps_path
  end

  def add_remote_components
    @app = find_app
    authorize! :add_remote_component, @app

    #@use_environments = AppEnvironmentGroup.environment_labels(@app.id)
    @remote_apps = App.active.name_order
    render layout: false
  end

  def create_remote_components
    @app = find_app
    authorize! :add_remote_component, @app

    application_environment_ids_to_update = params[:application_environment_ids_to_update] || []
    installed_component_ids = params[:installed_component_ids] || []
    err_messages = @app.add_remote_components(application_environment_ids_to_update, installed_component_ids)
    if err_messages.present?
      err_messages.each do |err|
        @app.errors.add(:base,err)
      end
      render action: :edit
    else
      redirect_to edit_app_path(@app, page: params[:page], key: params[:key])
    end
  end

  def application_environment_options
    app = App.find_by_id(params[:app_id])
    #@use_environments = AppEnvironmentGroup.environment_labels(app.id)
    render text: options_from_model_association(app, :application_environments, named_scope: :in_order)
  end

  def installed_component_options
    application_environment = ApplicationEnvironment.find_by_id(params[:application_environment_id]) if params[:application_environment_id].present?
    render text: options_from_model_association(application_environment, :installed_components)
  end

  def request_template_options
    templates = RequestTemplate.unarchived.visible('request_templates').by_app_id(params[:id]).uniq
    options = ["<option value=''>Unassigned</option>"]
    options += templates.map{ |template| "<option value='#{template.id}'>#{template.name}</option>" }
    render text: options.join(' ')
  end

  def route_options
    app = App.find_by_id(params[:app_id]) if params[:app_id].present?
    render text: options_from_model_association(app, :routes, text_method: :name_for_select, named_scope: [:in_name_order, :unarchived])
  end

  def upload_csv
    ::CsvImporter.import_component_properties!(params[:csv].read)
    redirect_to apps_path
  end

  def load_env_table
    render partial: 'users/form/edit_role_by_app_environment', locals: {app: find_app}
  end

  def can_work_with_app?
    @app = find_app
    unless @app.is_accessible_to?(current_user)
      # flash[:notice] = "Access Denied ! You do not have adequate permissions to access the page you requested."
      flash[:notice] = I18n.t(:'activerecord.notices.no_permissions', action: 'access', model: 'the page you requested')
      redirect_to(root_path)
    end
  end

  private

  def get_content_type(params)
    content_type = params[:app].content_type
    if content_type == 'text/xml' || content_type == 'application/json'
      content_type.gsub(/.*\//,'')
    else
      MIME::Types.of(params[:app].original_filename).first.extensions.first
    end
  end

  def components_to_export
    params.symbolize_keys.keys.select{ |key| key.in? OPTIONAL_EXPORT_COMPONENTS }
  end

  def alpha_reorder
    @app.alpha_sort_envs if @app.a_sorting_envs
    @app.alpha_sort_comps if @app.a_sorting_comps
  end

  def find_app
    App.find params[:id]
  end

  def warning_for_app_editing
    if params[:app] && params[:app][:team_ids] && !current_user.root?
      team_id = Array(params[:app][:team_ids]).first
      subject = PermissionGranter.get_subject(App.new)

      have_update_permission = AccessibleAppQuery.new(current_user, :update, subject).
        accessible_apps.where(teams: {id: team_id}).exists?

      flash[:warning] = I18n.t('team.without_app_edit') unless have_update_permission
    end
  end
end
