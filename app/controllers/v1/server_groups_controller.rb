class V1::ServerGroupsController < V1::AbstractRestController
  
  # Returns server_groups that are active by default
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/server_groups?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/server_groups?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><active>true</active></filters>' http://[rails_host]/v1/server_groups?token=[api_token]
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "active" : 'true' }}' -X GET http://[rails_host]/v1/server_groups?token=[api_token] 
  def index
    @server_groups = ServerGroup.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @server_groups.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => server_groups_presenter }
        format.json { render :json => server_groups_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a server_group by server_group id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/server_groups/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/server_groups/[id]?token=[api_token]
  def show
    @server_group = ServerGroup.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @server_group.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        
        format.xml { render :xml => server_group_presenter }
        format.json { render :json => server_group_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new server_group from a post request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the server_group (required, unique)
  # * +description+ - string description of the server_group 
  # * +environment_ids+ - array of integer ids for related environments
  # * +server_ids+ - array of integer ids for related servers
  # * +server_aspect_ids+ - array of integer ids for related server aspects
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d '<server_group><name>XML ServerGroup</name></server_group>'  http://[rails_host]/v1/server_groups?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "server_group": { "name" : "JSONRenamedServerGroup" }}'  http://[rails_host]/v1/server_groups?token=[api_token]
  
  def create
    @server_group = ServerGroup.new
    respond_to do |format|
      begin
        success = @server_group.update_attributes(params[:server_group])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => server_group_presenter, :status => :created }
        format.json  { render :json => server_group_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @server_group.errors, :status => :unprocessable_entity }
        format.json  { render :json => @server_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing server_group with values from a PUT request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the server_group (required, unique)
  # * +description+ - string description of the server_group 
  # * +environment_ids+ - array of integer ids for related environments
  # * +server_ids+ - array of integer ids for related servers
  # * +server_aspect_ids+ - array of integer ids for related server aspects
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<server_group><name>XML ServerGroup</name></server_group>' http://[rails_host]/v1/server_groups/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "server_group": { "name" : "JSONRenamedServerGroup" }}'  http://[rails_host]/v1/server_groups/[id]?token=[api_token] 
  def update
    @server_group = ServerGroup.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @server_group
        begin
          success = @server_group.update_attributes(params[:server_group])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => server_group_presenter, :status => :accepted }
          format.json  { render :json => server_group_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @server_group.errors, :status => :unprocessable_entity }
          format.json  { render :json => @server_group.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a server_group by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/server_groups/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/server_groups/[id]?token=[api_token]
  def destroy
    @server_group = ServerGroup.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @server_group
        success = @server_group.try(:deactivate!) rescue false
        
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => server_group_presenter, :status => :precondition_failed }
          format.json { render :json => server_group_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end
  
  private

  # helper for loading the server_groups presenter
  def server_groups_presenter
    @server_groups_presenter ||= V1::ServerGroupsPresenter.new(@server_groups, @template)
  end
    
  # helper for loading the server_group present  
  def server_group_presenter
    @server_group_presenter ||= V1::ServerGroupPresenter.new(@server_group, @template)
  end
end
