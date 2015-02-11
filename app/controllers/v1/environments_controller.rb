################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::EnvironmentsController < V1::AbstractRestController

  before_filter :set_include_except

  # Returns environments that are active by default
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/environments?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/environments?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><active>true</active></filters>' http://[rails_host]/v1/environments?token=[api_token]
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "active" : 'true' }}' -X GET http://[rails_host]/v1/environments?token=[api_token]
  def index
    @environments = Environment.filtered(params[:filters]) rescue nil
    respond_to do |format|
      if @environments.present?
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => environments_presenter }
        format.json { render :json => environments_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a environment by environment id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/environments/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/environments/[id]?token=[api_token]
  def show
    @environment = Environment.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @environment.present?
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => environment_presenter }
        format.json { render :json => environment_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new environment from a post request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the environment (required, unique)
  # * +default_server_group_id+ - integer id of default server group id (optional)
  # * +active+ - boolean for active (optional, default true)
  # * +default+ - boolean for default (optional, default false)
  # * +server_ids+ - array of integer ids for related servers
  # * +server_group_ids+ - array of integer ids for related server groups
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<environment><name>XML Environment</name></environment>'  http://[rails_host]/v1/environments?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "environment": { "name" : "JSONRenamedEnvironment" }}'  http://[rails_host]/v1/environments?token=[api_token]

  def create
    @environment = Environment.new
    respond_to do |format|
      begin
        success = @environment.update_attributes(params[:environment])
      rescue Exception => e
        @exception = { message: e.message, backtrace: e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => environment_presenter, :status => :created }
        format.json  { render :json => environment_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @environment.errors, :status => :unprocessable_entity }
        format.json  { render :json => @environment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing environment with values from a PUT request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the environment (required, unique)
  # * +default_server_group_id+ - integer id of default server group id (optional)
  # * +active+ - boolean for active (optional, default true)
  # * +default+ - boolean for default (optional, default false)
  # * +server_ids+ - array of integer ids for related servers
  # * +server_group_ids+ - array of integer ids for related server groups
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<environment><name>XML Environment</name></environment>' http://[rails_host]/v1/environments/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "environment": { "name" : "JSONRenamedEnvironment" }}'  http://[rails_host]/v1/environments/[id]?token=[api_token]
  def update
    @environment = Environment.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @environment
        begin
          success = @environment.update_attributes(params[:environment])
        rescue Exception => e
          @exception = { message: e.message, backtrace: e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => environment_presenter, :status => :accepted }
          format.json  { render :json => environment_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @environment.errors, :status => :unprocessable_entity }
          format.json  { render :json => @environment.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a environment by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/environments/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/environments/[id]?token=[api_token]
  def destroy
    @environment = Environment.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @environment
        success = @environment.try(:deactivate!) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => environment_presenter, :status => :precondition_failed }
          format.json { render :json => environment_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the environments presenter
  def environments_presenter
    @environments_presenter ||= V1::EnvironmentsPresenter.new(@environments, @template, {include_except: @include_except})
  end

  # helper for loading the environment present
  def environment_presenter
    @environment_presenter ||= V1::EnvironmentPresenter.new(@environment, @template, {include_except: @include_except})
  end
end
