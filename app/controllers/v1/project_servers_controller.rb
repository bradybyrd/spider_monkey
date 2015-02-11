class V1::ProjectServersController < V1::AbstractRestController
  
  # Returns project_servers that are active by default
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/project_servers?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/project_servers?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><name>Sample ProjectServer</name></filters>' http://[rails_host]/v1/project_servers?token=[api_token]
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "name" : 'SampleProjectServer' }}' -X GET http://[rails_host]/v1/project_servers?token=[api_token] 
  def index
    @project_servers = ProjectServer.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @project_servers.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => project_servers_presenter }
        format.json { render :json => project_servers_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a project_server by project_server id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/project_servers/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/project_servers/[id]?token=[api_token]
  def show
    @project_server = ProjectServer.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @project_server.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        
        format.xml { render :xml => project_server_presenter }
        format.json { render :json => project_server_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new project_server from a post request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the project_server (required, unique)
  # * +server_name_id+ - integer of the integration server type ("Rally" => 1, "Jira" => 2, "Mantis" => 3, "ServiceNow" => 4, "Hudson" => 5, "SSH" => 6, "Streamstep" => 7)
  # * +server_url+ - string url of the server (required)
  # * +ip+ - string ip address for the integration server
  # * +port+ - integer port number for the integration server (optional except for Jira server name id 2)
  # * +username+ - string username for the integration server (required)
  # * +password+ - string password for the integration server
  # * +details+ - string description of the integration server
  # * +query_ids+ - array of integer ids for related queries
  # * +project_ids+ - array of integer ids for related projects
  # * +release_ids+ - array of integer ids for releases
  # * +ticket_ids+ - array of integer ids for tickets
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<project_server><name>XML ProjectServer</name></project_server>'  http://[rails_host]/v1/project_servers?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d \n '{ "project_server": { "name" : "JSONRenamedProjectServer" }}'  http://[rails_host]/v1/project_servers?token=[api_token]
  
  def create
    @project_server = ProjectServer.new
    respond_to do |format|
      begin
        success = @project_server.update_attributes(params[:project_server])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => project_server_presenter, :status => :created }
        format.json  { render :json => project_server_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @project_server.errors, :status => :unprocessable_entity }
        format.json  { render :json => @project_server.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing project_server with values from a PUT request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the project_server (required, unique)
  # * +server_name_id+ - integer of the integration server type ("Rally" => 1, "Jira" => 2, "Mantis" => 3, "ServiceNow" => 4, "Hudson" => 5, "SSH" => 6, "Streamstep" => 7)
  # * +server_url+ - string url of the server (required)
  # * +ip+ - string ip address for the integration server
  # * +port+ - integer port number for the integration server (optional except for Jira server name id 2)
  # * +username+ - string username for the integration server (required)
  # * +password+ - string password for the integration server
  # * +details+ - string description of the integration server
  # * +query_ids+ - array of integer ids for related queries
  # * +project_ids+ - array of integer ids for related projects
  # * +release_ids+ - array of integer ids for releases
  # * +ticket_ids+ - array of integer ids for tickets
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<project_server><name>XML ProjectServer</name><active>false</active></project_server>' http://[rails_host]/v1/project_servers/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "project_server": { "name" : "JSONRenamedProjectServer", "user_id": 1 }}'  http://[rails_host]/v1/project_servers/[id]?token=[api_token] 
  def update
    @project_server = ProjectServer.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @project_server
        begin
          success = @project_server.update_attributes(params[:project_server])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => project_server_presenter, :status => :accepted }
          format.json  { render :json => project_server_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @project_server.errors, :status => :unprocessable_entity }
          format.json  { render :json => @project_server.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a project_server by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/project_servers/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/project_servers/[id]?token=[api_token]
  def destroy
    @project_server = ProjectServer.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @project_server
        success = @project_server.try(:deactivate!) rescue false
        
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => project_server_presenter, :status => :precondition_failed }
          format.json { render :json => project_server_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end
  
  private

  # helper for loading the project_servers presenter
  def project_servers_presenter
    @project_servers_presenter ||= V1::ProjectServersPresenter.new(@project_servers, @template)
  end
    
  # helper for loading the project_server present  
  def project_server_presenter
    @project_server_presenter ||= V1::ProjectServerPresenter.new(@project_server, @template)
  end
end
