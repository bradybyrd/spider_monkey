class V1::ServersController < V1::AbstractRestController
  
  # Returns servers that are active by default
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/servers?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/servers?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><active>true</active></filters>' http://[rails_host]/v1/servers?token=[api_token]
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "active" : 'true' }}' -X GET http://[rails_host]/v1/servers?token=[api_token] 
  def index
    @servers = Server.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @servers.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => servers_presenter }
        format.json { render :json => servers_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a server by server id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/servers/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/servers/[id]?token=[api_token]
  def show
    @server = Server.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @server.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        
        format.xml { render :xml => server_presenter }
        format.json { render :json => server_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new server from a post request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the server (required, unique)
  # * +dns+ - string dns name of the server 
  # * +ip_address+ - string ip address 
  # * +os_platform+ - string name of operating system platform
  # * +environment_ids+ - array of integer ids for related environments
  # * +server_group_ids+ - array of integer ids for related server groups
  # * +property_ids+ - array of integer ids for related properties
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<server><name>XML Server</name></server>'  http://[rails_host]/v1/servers?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "server": { "name" : "JSONRenamedServer" }}'  http://[rails_host]/v1/servers?token=[api_token]
  
  def create
    @server = Server.new
    respond_to do |format|
      begin
        success = @server.update_attributes(params[:server])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => server_presenter, :status => :created }
        format.json  { render :json => server_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
        format.json  { render :json => @server.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing server with values from a PUT request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the server (required, unique)
  # * +dns+ - string dns name of the server 
  # * +ip_address+ - string ip address 
  # * +os_platform+ - string name of operating system platform
  # * +environment_ids+ - array of integer ids for related environments
  # * +server_group_ids+ - array of integer ids for related server groups
  # * +property_ids+ - array of integer ids for related properties
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<server><name>XML Server</name></server>' http://[rails_host]/v1/servers/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "server": { "name" : "JSONRenamedServer" }}'  http://[rails_host]/v1/servers/[id]?token=[api_token] 
  def update
    @server = Server.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @server
        begin
          success = @server.update_attributes(params[:server])
        rescue ActiveRecord::RecordInvalid
          success = false
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => server_presenter, :status => :accepted }
          format.json  { render :json => server_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @server.errors, :status => :unprocessable_entity }
          format.json  { render :json => @server.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a server by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/servers/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/servers/[id]?token=[api_token]
  def destroy
    @server = Server.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @server
        success = @server.try(:deactivate!) rescue false
        
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => server_presenter, :status => :precondition_failed }
          format.json { render :json => server_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end
  
  private

  # helper for loading the servers presenter
  def servers_presenter
    @servers_presenter ||= V1::ServersPresenter.new(@servers, @template)
  end
    
  # helper for loading the server present  
  def server_presenter
    @server_presenter ||= V1::ServerPresenter.new(@server, @template)
  end
end
