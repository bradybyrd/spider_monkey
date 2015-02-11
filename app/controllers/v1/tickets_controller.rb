class V1::TicketsController < V1::AbstractRestController

  # Returns tickets that are not deleted nor archived
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication  
  # * +filters+ - Filters criteria for getting subset of installed_components, can be - "app_id", "app_name", "ticket_status", "lifecycle_id", "step_id", "request_id", "foreign_id", "project_server_id"
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/tickets?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/tickets?token=[api_token]
  def index
    @tickets = Ticket.filtered(nil, params[:filters]) rescue nil
    respond_to do |format|
      unless @tickets.blank?
        format.xml { render :xml => tickets_presenter }
        format.json { render :json => tickets_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a ticket by ticket id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/tickets/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/tickets/[id]?token=[api_token]
  def show
    @ticket = Ticket.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @ticket.blank?
        format.xml { render :xml => ticket_presenter }
        format.json { render :json => ticket_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new ticket from a posted XML document
  #
  # ==== Attributes
  #
  # * +foreign_id+ - string foreign id of the ticket
  # * +name+ - string name of the ticket
  # * +status+ - string status of the ticket
  # * +ticket_type+ - string type of the ticket
  # * +project_server_id+ - integer id of the project server that this ticket belongs to (required)  
  # * +app_id+ - integer id of a parent app
  # * +plan_ids+ - array of integer ids of the lifecycles this ticket should be attached to (required)  
  # * +step_ids+ - array of integer ids of the steps to which the ticket relates
  # * +related_ticket_ids+ - array of integer ids of the tickets to which the ticket is related
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # Finder methods that look up a matching object and set the corresponding id field
  #
  # * +app_name+ - string name of an application (short code prefix delimited with _|_ or full name)
  # * +lifecycle_names+ - an array of string names of lifecyles 
  #
  # * Note: app_name can be searched using a prefix if the delimiter '_|_' is used in the application name.  For example, searching for 
  # 'BRPM' will find installed components associated with 'BRPM_|_BMC Release Process Management'.
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
  #   curl -i -H "accept: text/xml" -X POST -d "ticket[foreign_id]=Geade2&ticket[name]=Testticket&ticket[project_server_id]=1&ticket[plan_ids]=5&token=[...your token...]" http://[rails_host]/v1/tickets
  #   curl -i -H "accept: text/xml  -H "Content-type: text/xml" -X POST -d @create_ticket.xml http://[rails_host]/v1/tickets?token=[...your token ...]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "ticket": { "foreign_id" : "GEADE5", "name" : "JSONRenamedticket", "project_server_id" : 5, "lifecycle_ids" : 10}}' http://[rails_host]/v1/tickets/?token=[api_token]
  def create
    respond_to do |format|
      begin
       @ticket = Ticket.new
       success = @ticket.update_attributes(params[:ticket])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => ticket_presenter, :status => :created }
        format.json  { render :json => ticket_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @ticket.errors, :status => :unprocessable_entity }
        format.json  { render :json => @ticket.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing ticket with values from a posted XML document
  #
  # ==== Attributes
  #
  # * +foreign_id+ - string foreign id of the ticket
  # * +name+ - string name of the ticket
  # * +status+ - string status of the ticket
  # * +ticket_type+ - string type of the ticket
  # * +project_server_id+ - integer id of the project server that this ticket belongs to (required)  
  # * +app_id+ - integer id of a parent app
  # * +lifecycle_ids+ - array of integer ids of the lifecycles this ticket should be attached to (required)  
  # * +step_ids+ - array of integer ids of the steps to which the ticket relates
  # * +related_ticket_ids+ - array of integer ids of the tickets to which the ticket is related
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # Finder methods that look up a matching object and set the corresponding id field
  #
  # * +app_name+ - string name of an application 
  # * +lifecycle_names+ - an array of string names of lifecyles 
  #
  # * Note: app_name can be searched using a prefix if the delimiter '_|_' is used in the application name.  For example, searching for 
  # 'BRPM' will find installed components associated with 'BRPM_|_BMC Release Process Management'.
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
  #   curl -i -H "accept: text/xml" -X PUT -d "ticket[foreign_id]=NewId&ticket[name]=NewName&ticket[plan_ids]=19&token=[...your token...]" http://[rails_host]/v1/tickets/[id]
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d @ticket_update.xml http://[rails_host]/v1/tickets/[id]?token=[...your token...]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "ticket": { "foreign_id" : "DE23333", "name" : "Rename Ticket", "status":"Rejected"}}'  http://[rails_host]/v1/tickets/[id]?token=[...your token...]
  def update
    @ticket = Ticket.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @ticket
        begin
          success = @ticket.update_attributes(params[:ticket])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => ticket_presenter, :status => :accepted }
          format.json  { render :json => ticket_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @ticket.errors, :status => :unprocessable_entity }
          format.json  { render :json => @ticket.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Deletes a ticket
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/tickets/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/tickets/[id]?token=[api_token]
  def destroy
    @ticket = Ticket.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @ticket
        success = @ticket.destroy rescue false
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => ticket_presenter, :status => :precondition_failed }
          format.json { render :json => ticket_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private
  # Private methods below

  # helper for loading the tickets presenter
  def tickets_presenter
    @tickets_presenter ||= V1::TicketsPresenter.new(@tickets, @template)
  end
    
  # helper for loading the ticket present  
  def ticket_presenter
    @ticket_presenter ||= V1::TicketPresenter.new(@ticket, @template)
  end

end
