################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::GroupsController < V1::AbstractRestController

  before_filter :set_include_except

  # Returns groups that are active by default
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/groups?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/groups?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><active>true</active></filters>' http://[rails_host]/v1/groups?token=[api_token]
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "active" : 'true' }}' -X GET http://[rails_host]/v1/groups?token=[api_token]
  def index
    @groups = Group.filtered(params[:filters]) rescue nil
    respond_to do |format|
      if @groups.present?
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => groups_presenter }
        format.json { render :json => groups_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a group by group id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/groups/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/groups/[id]?token=[api_token]
  def show
    @group = Group.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @group.present?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => group_presenter }
        format.json { render :json => group_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new group from a post request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the group (required, unique)
  # * +email+ - string email of group owner or group mailing list (optional)
  # * +active+ - boolean for active (optional, default true)
  # * +team_ids+ - array of integer ids for related teams
  # * +resource_ids+ - array of integer ids for related users called "resources" for the group
  # * +resource_manager_ids+ - array of integer ids for related users assigned as resource managers (maximum 2)
  # * +container_ids+ - array of integer ids for related containers
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Accepts Nested Attributes for Creation and Update of Associated Objects
  #
  # * +group with release_attributes - this will accept nested attributes for an existing or a new release
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<group><name>XML Group</name></group>'  http://[rails_host]/v1/groups?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d \n '{ "group": { "name" : "JSONRenamedGroup" }}'  http://[rails_host]/v1/groups?token=[api_token]

  def create
    @group = Group.new
    respond_to do |format|
      begin
        success = @group.update_attributes(params[:group])
      rescue Exception => e
        @exception = { message: e.message, backtrace: e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => group_presenter, :status => :created }
        format.json  { render :json => group_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
        format.json  { render :json => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing group with values from a PUT request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the group (required, unique)
  # * +email+ - string email of group owner or group mailing list (optional)
  # * +active+ - boolean for active (optional, default true)
  # * +team_ids+ - array of integer ids for related teams
  # * +resource_ids+ - array of integer ids for related users called "resources" for the group
  # * +resource_manager_ids+ - array of integer ids for related users assigned as resource managers (maximum 2)
  # * +container_ids+ - array of integer ids for related containers
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<group><name>XML Group</name><active>false</active></group>' http://[rails_host]/v1/groups/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "group": { "name" : "JSONRenamedGroup", "user_id": 1 }}'  http://[rails_host]/v1/groups/[id]?token=[api_token]
  def update
    @group = Group.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @group
        begin
          success = @group.update_attributes(params[:group])
        rescue Exception => e
          @exception = { message: e.message, backtrace: e.backtrace.inspect }
        end

        if success
          @group.users.update_all(terminate_session: true)
          format.xml  { render :xml => group_presenter, :status => :accepted }
          format.json  { render :json => group_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
          format.json  { render :json => @group.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a group by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/groups/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/groups/[id]?token=[api_token]
  def destroy
    @group = Group.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @group
        success = @group.try(:deactivate!) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => group_presenter, :status => :precondition_failed }
          format.json { render :json => group_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the groups presenter
  def groups_presenter
    @groups_presenter ||= V1::GroupsPresenter.new(@groups, @template, {include_except: @include_except})
  end

  # helper for loading the group present
  def group_presenter
    @group_presenter ||= V1::GroupPresenter.new(@group, @template, {include_except: @include_except})
  end
end
