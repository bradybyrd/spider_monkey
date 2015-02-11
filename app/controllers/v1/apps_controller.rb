################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::AppsController < V1::AbstractRestController

  before_filter :set_include_except

  # Returns apps that are active by default
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  # * +filters+ - active:boolean, inactive:boolean, name:string
  #
  # TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE']
  # FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE']
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 404 Not Found - When no records are found.
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/apps?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/apps?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><name>Sample App</name></filters>' http://[rails_host]/v1/apps?token=[api_token]
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "name" : 'SampleApp' }}' -X GET http://[rails_host]/v1/apps?token=[api_token]
  def index
    @apps = App.filtered(params[:filters]) rescue nil
    respond_to do |format|
      if @apps.present?
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => apps_presenter }
        format.json { render :json => apps_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a app by app id
  #
  # ==== Attributes
  #
  # * +id+ - numerical unique id for record
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 404 Not found - When record to show is not found.
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/apps/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/apps/[id]?token=[api_token]
  def show
    if params[:export_xml] || params[:export_app]
      params[:export_app] = true
      @app = App.export(params[:id].to_i) rescue nil
    else
      @app = App.find(params[:id].to_i) rescue nil
    end
    respond_to do |format|
      if @app.present?
        if params[:export_xml] || params[:export_app]
          presenter = apps_presenter_detailed(params[:optional_components])
          format.xml  { render xml: presenter }
          format.json do
            if params[:export_xml]
              render xml: presenter
            else
              render json: presenter
            end
          end
        else
          format.xml { render xml: app_presenter }
          format.json { render json: app_presenter }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new app from a post request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the app (required, unique)
  # * +app_version+ - integer of an existing user id
  # * +active+ - boolean for active (optional, default true)
  # * +default+ - boolean for default application (optional, default false)
  # * +environment_ids+ - array of integer ids for related environments
  # * +component_ids+ - array of integer ids for related components
  # * +installed_component_ids+ - array of integer ids for related installed_components
  # * +team_ids+ - array of integer ids for related teams
  # * +user_ids+ - array of integer ids for related users
  # * +ticket_ids+ - array of integer ids for related tickets
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Accepts Nested Attributes for Creation and Update of Associated Objects
  #
  # * +app with release_attributes - this will accept nested attributes for an existing or a new release
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 422 Unprocessable entity - When validation fails, objects and errors are returned
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<app><name>XML App</name></app>'  http://[rails_host]/v1/apps?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d \n '{ "app": { "name" : "JSONRenamedApp" }}'  http://[rails_host]/v1/apps?token=[api_token]

  def create
    @app = App.new
    respond_to do |format|
      begin
        if params[:app_import].present?
          if params[:app_import][:app].present?
            import_data = params[:app_import]
            team = Team.find_by_name!(params[:app_import][:team])
            @app = App.import(import_data, current_user, team, 'hash')
            success = @app.errors.none?
          else
            success = false
            @app.errors.add(:app_import, 'app tag missing.')
          end
        else
          @app.assign_attributes(params[:app])
          success = TeamPresenceAppValidator.new(@app).valid? && @app.save
        end
      rescue Exception => e
        @exception = { message: e.message, backtrace: e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => app_presenter, :status => :created }
        format.json  { render :json => app_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @app.errors, :status => :unprocessable_entity }
        format.json  { render :json => @app.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing app with values from a PUT request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the app (required, unique)
  # * +app_version+ - integer of an existing user id
  # * +active+ - boolean for active (optional, default true)
  # * +default+ - boolean for default application (optional, default false)
  # * +environment_ids+ - array of integer ids for related environments
  # * +component_ids+ - array of integer ids for related components
  # * +installed_component_ids+ - array of integer ids for related installed_components
  # * +team_ids+ - array of integer ids for related teams
  # * +user_ids+ - array of integer ids for related users
  # * +ticket_ids+ - array of integer ids for related tickets
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 404 Not found - When record to update is not found.
  # * ERROR 422 Unprocessable entity - When validation fails, objects and errors are returned
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<app><name>XML App</name><active>false</active></app>' http://[rails_host]/v1/apps/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "app": { "name" : "JSONRenamedApp", "user_id": 1 }}'  http://[rails_host]/v1/apps/[id]?token=[api_token]
  def update
    @app = App.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @app
        begin
          success = @app.update_attributes(params[:app])
        rescue Exception => e
          @exception = { message: e.message, backtrace: e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => app_presenter, :status => :accepted }
          format.json  { render :json => app_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @app.errors, :status => :unprocessable_entity }
          format.json  { render :json => @app.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a app by deactivating them
  #
  # ==== Attributes
  #
  # * +id+ - numerical unique id for record
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 404 Not found - When no records are found.
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/apps/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/apps/[id]?token=[api_token]
  def destroy
    @app = App.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @app
        success = @app.try(:deactivate!) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => app_presenter, :status => :precondition_failed }
          format.json { render :json => app_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  def apps_presenter
    @apps_presenter ||= V1::AppsPresenter.new(@apps, @template, {include_except: @include_except})
  end

  def app_presenter
    @app_presenter ||= V1::AppPresenter.new(@app, @template, {include_except: @include_except})
  end

  def apps_presenter_detailed(optional_components_params)
    @apps_presenter ||= V1::AppsPresenter.new(@app, nil, { export_app: true, optional_components: components_to_export(optional_components_params) })
  end

  def components_to_export(optional_components_params)
    optional_components = []
    if optional_components_params && optional_components_params.include?('[') && optional_components_params.include?(']')
      optional_components = optional_components_params.gsub(/(\[|\])/, '').downcase.split(',').map(&:to_sym)
    end
    optional_components
  end

end
