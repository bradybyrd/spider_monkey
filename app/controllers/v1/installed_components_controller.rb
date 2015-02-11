################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::InstalledComponentsController < V1::AbstractRestController

  before_filter :set_include_except

  # Returns installed_components that are active
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  # * +filters+ - Filters criteria for getting subset of installed_components, can be - "app_id", "environment_id", "component_id", "app_name", "component_name", "environment_name", "server_group_name"
  #
  # * Note: app_name can be searched using a prefix if the delimiter '_|_' is used in the application name.  For example, searching for
  # 'BRPM' will find installed components associated with 'BRPM_|_BMC Release Process Management'.
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/installed_components?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/installed_components?token=[api_token]
  #
  # Filter example with json:
  #   curl -i -H "accept: application/json" -X -d '{ "filters": { "app_name":"BRPM" } }' GET http://[rails_host]/v1/installed_components?token=[api_token]

  def index
    @installed_components = InstalledComponent.filtered(params[:filters]) rescue nil
    respond_to do |format|
      if @installed_components.present?
        # to provide a installed_component specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => installed_components_presenter }
        format.json { render :json => installed_components_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns an installed_component by installed_component id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/installed_components/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/installed_components/[id]?token=[api_token]

  def show
    @installed_component = InstalledComponent.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @installed_component.present?
        # to provide a installed_component specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => installed_component_presenter }
        format.json { render :json => installed_component_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new installed component from a posted XML document
  #
  # ==== Attributes
  #
  # Mandatory finder methods that lookup and (if found) link this installed component to the named models
  # * +app_name+ - string name of the application
  # * +component_name+ - string name of the parent component object
  # * +environment_name+ - string name of the environment object
  #
  # * Note: app_name can be searched using a prefix if the delimiter '_|_' is used in the application name.  For example, searching for
  # 'BRPM' will find installed components associated with 'BRPM_|_BMC Release Process Management'.
  #
  # Note: you must indicate all three mandatory fields to create an installed component
  #
  # Optional finder methods that lookup and (if found) link this installed component to the named models
  # * +server_names+ - string or array of string names of the servers
  # * +server_aspect_names+ -string or array of string names of the server aspects
  # * +server_aspect_group_names+ -string or array of string names of the server aspect groups
  # * +server_group_name+ - string name of the single associated server group (through default server group id)
  #
  # Special property setting accessor that takes key value pairs and attaches them to the installed component
  # Note: property must already exist AND must be assigned to the component
  # * +properties_with_values+ - hash of key value pairs such as { 'server_url' => 'localhost', 'user_name' => 'admin' }
  #
  # Available but typically unused fields used to link the installed component to parent apps, components, and environments
  # * +application_component_id+ - integer id of application component model (see special finders below to avoid having to create this object manually)
  # * +application_environment_id+ - integer id of application_environment model (see special finders below to avoid having to create this object manually)
  #
  # Additional optional metadata fields for the installed component
  # * +default_server_group_id+ - integer id of the default server group
  # * +location+ - string field storing the physical or virtual location of the installed component
  # * +version+ - string field showing the current version of the installed component
  # * +reference_id+ - integer field linking the installed component to another installed component
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 422 Unprocessable entity - When validation fails, objects and errors are returned
  #
  # ==== Examples=
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml"  -H "Content-type: text/xml" -X POST -d "<installed_component><app_name>BRPM</app_name><component_name>SS_MySQL</component_name><environment_name>production</name></installed_component>" http://[rails_host]/v1/installed_components?token=[...your token ...]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "installed_component": { "app_name" : "BRPM", "component_name" : "SS_MySQL", "environment_name" : "production" }}' http://[rails_host]/v1/installed_components/?token=[api_token]

  def create
    @installed_component = InstalledComponent.new
    success = false
    respond_to do |format|
      begin
        success = @installed_component.update_attributes(params[:installed_component])
      rescue Exception => e
        @exception = { message: e.message, backtrace: e.backtrace.inspect }
      end
      if success
        format.xml  { render :xml => installed_component_presenter, :status => :created }
        format.json  { render :json => installed_component_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @installed_component.errors, :status => :unprocessable_entity }
        format.json  { render :json => @installed_component.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing installed_component with values from a posted XML document
  #
  # ==== Attributes
  #
  # Mandatory finder methods that lookup and (if found) link this installed component to the named models
  # * +app_name+ - string name of the application
  # * +component_name+ - string name of the parent component object
  # * +environment_name+ - string name of the environment object
  #
  # Note: you must indicate all three mandatory fields to create an installed component
  #
  # Optional finder methods that lookup and (if found) link this installed component to the named models
  # * +server_names+ - string or array of string names of the servers
  # * +server_aspect_names+ -string or array of string names of the server aspects
  # * +server_aspect_group_names+ -string or array of string names of the server aspect groups
  # * +server_group_name+ - string name of the single associated server group (through default server group id)
  #
  # Special property setting accessor that takes key value pairs and attaches them to the installed component
  # Note: property must already exist AND must be assigned to the component
  # * +properties_with_values+ - hash of key value pairs such as { 'server_url' => 'localhost', 'user_name' => 'admin' }
  #
  # Available but typically unused fields used to link the installed component to parent apps, components, and environments
  # * +application_component_id+ - integer id of application component model (see special finders below to avoid having to create this object manually)
  # * +application_environment_id+ - integer id of application_environment model (see special finders below to avoid having to create this object manually)
  #
  # Additional optional metadata fields for the installed component
  # * +default_server_group_id+ - integer id of the default server group
  # * +location+ - string field storing the physical or virtual location of the installed component
  # * +version+ - string field showing the current version of the installed component
  # * +reference_id+ - integer field linking the installed component to another installed component
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<installed_component_xml>' http://0.0.0.0:3000/v1/installed_components/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ installed_component_json }|'  http://[rails_host]/v1/installed_components/[id]?token=[api_token]

  def update
    @installed_component = InstalledComponent.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @installed_component
        begin
          success = @installed_component.update_attributes(params[:installed_component])
        rescue Exception => e
          @exception = { message: e.message, backtrace: e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => installed_component_presenter, :status => :accepted }
          format.json  { render :json => installed_component_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @installed_component.errors, :status => :unprocessable_entity }
          format.json  { render :json => @installed_component.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a installed_component by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/installed_components/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/installed_components/[id]?token=[api_token]

  def destroy
    @installed_component = InstalledComponent.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @installed_component
        success = @installed_component.try(:deactivate!) rescue false

        if success
          format.xml { render :xml => installed_component_presenter, :status => :accepted }
          format.json { render :json => installed_component_presenter, :status => :accepted }
        else
          format.xml { render :xml => installed_component_presenter, :status => :precondition_failed }
          format.json { render :json => installed_component_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the installed components presenter
  def installed_components_presenter
    @installed_components_presenter ||= V1::InstalledComponentsPresenter.new(@installed_components, @template, {include_except: @include_except})
  end

  # helper for loading the installed_component present
  def installed_component_presenter
    @installed_component_presenter ||= V1::InstalledComponentPresenter.new(@installed_component, @template, {include_except: @include_except})
  end

end