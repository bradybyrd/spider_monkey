class V1::RequestsController < V1::AbstractRestController

  before_filter :translate_names_to_ids, :only => [:create]

  # Returns requests that are not deleted nor archived
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/requests?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/requests?token=[api_token]
  def index
    @requests = Request.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @requests.try(:empty?)
        format.xml { render :xml => requests_presenter }
        format.json { render :json => requests_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a request by request id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/requests/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/requests/[id]?token=[api_token]

  def show
    @request = Request.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @request.blank?
        format.xml { render :xml => request_presenter }
        format.json { render :json => request_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new request from a posted XML document
  #
  # ==== Attributes
  #
  # * +id+ - numerical unique id for record to be updated  
  # * +request[name]+ - string name of the request
  # * +request[requestor_id]+ - integer id of the requestor (required)
  # * +request[deployment_coordinator_id]+ - integer id of the deployment coordinator (required)  
  # * +request[...]+ - other valid request fields
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d "<request> <name>Rest Request</name> <deployment_coordinator_id>1</deployment_coordinator_id> <requestor_id>1</requestor_id> </request>" http://[rails_host]/v1/requests?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "request": { "name" : "JSONRenamedRequest", "requestor_id" : 1, "deployment_coordinator_id" : 1}}' http://[rails_host]/v1/requests/?token=[api_token]
  def create
    respond_to do |format|
      begin
        success = create_requests
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => request_presenter, :status => :created }
        format.json  { render :json => request_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @request.errors, :status => :unprocessable_entity }
        format.json  { render :json => @request.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing request with values from a posted XML document
  #
  # ==== Attributes
  #
  # * +request[...]+ - other valid request fields
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
  #   curl -i -H "accept: text/xml" -X PUT -d "request[name]=NewName&request[description]=Hello&request[aasm_state]='resolve'&request[aasm_event_note]='event status notes'&token=[...your token...]" http://[rails_host]/v1/requests/[id]  
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "request": { "name" : "JSONRenamedRequest", "description":"JSON Hello"}}'  http://[rails_host]/v1/requests/[id] 
  def update
    @request = Request.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @request
        begin
          success = @request.update_attributes(params[:request])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => request_presenter, :status => :accepted }
          format.json  { render :json => request_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @request.errors, :status => :unprocessable_entity }
          format.json  { render :json => @request.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Deletes a request
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/requests/[id].xml?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/requests/[id].xml?token=[api_token]
  def destroy
    @request = Request.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @request
        success = @request.destroy rescue false
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => request_presenter, :status => :precondition_failed }
          format.json { render :json => request_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end
  
  private

  # helper for loading the requests presenter
  def requests_presenter
    @requests_presenter ||= V1::RequestsPresenter.new(@requests, @template)
  end
    
  # helper for loading the request present  
  def request_presenter
    @request_presenter ||= V1::RequestPresenter.new(@request, @template)
  end

  # helper that translates entities like environment name and template names to ids in params
  def translate_names_to_ids
    return if params[:request].nil?

    if params[:request][:environment] && params[:request][:environment_id].nil?
      params[:request][:environment_id] = Environment.active.find_by_name(params[:request][:environment]).id rescue nil
      params[:request].delete(:environment)
    end

    ### TODO implement translate multiple environments names to ids

    if params[:request][:template_name] && params[:request][:request_template_id].nil?
      params[:request][:request_template_id] = RequestTemplate.unarchived.find_by_name(params[:request][:template_name]).id rescue nil
      params[:request].delete(:template_name) unless params[:request][:request_template_id].nil?
    end
  end

  def create_requests
    environment_ids = MultipleEnvsRequestForm.parse_env_ids_from_params(params)
    @request = Request.new(params[:request].except(:execute_now))
    if MultipleEnvsRequestForm.no_one_environment?(params[:request], environment_ids)
      @request.errors.add(:environment, I18n.t(:'request.validations.at_least_one_env'))
    end
    @request.check_compliance_and_dw_errors(environment_ids)

    return false if @request.errors.present?

    params[:request][:environment_id] = environment_ids.first if environment_ids.present?

    if params[:request].has_key?('request_template_id')
      success = create_requests_from_template(environment_ids)
    else
      success = @request.update_attributes(params[:request])
      params[:request][:should_time_stitch] = false
      MultipleEnvsRequestForm.create_multiple_requests(@request, environment_ids, params) if success
    end
    success
  end

  def create_requests_from_template(environment_ids)
    raise "Template #{params[:request][:template_name]} not found " if params[:request][:request_template_id].blank?

    @request_template = RequestTemplate.unarchived.find_by_id(params[:request][:request_template_id])
    params[:request].delete(:request_template_id)
    form_params = params[:request].dup
    @request = @request_template.instantiate_request(params)
    return false if @request.id.blank?
    params[:request] = form_params
    MultipleEnvsRequestForm.instantiate_multiple_requests(@request_template, environment_ids, params)
    true
  end

end
