class V1::StepsController < V1::AbstractRestController
  
  # Returns steps that are not deleted nor archived
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  # * +filters+ - TBD
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/steps?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/steps?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><aasm_state>created</aasm_state><aasm_state>planned</aasm_state></filters>' http://[rails_host]/v1/steps?token=[api_token]
  #
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "aasm_state" : ["created","planned"] }}' -X GET http://[rails_host]/v1/steps?token=[api_token] d
  def index
    @steps = Step.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @steps.blank?
        format.xml { render :xml => steps_presenter }
        format.json { render :json => steps_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a step by step id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/steps/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/steps/[id]?token=[api_token]
  def show
    @step = Step.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @step.blank?
        format.xml { render :xml => step_presenter }
        format.json { render :json => step_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Send email notification
  #
   # ==== Attributes
  #
  # * +id+ - numerical unique id for record
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  # * ERROR 400 Bad Request - When mail not sent
  # ==== Examples
  #
  # curl -i -H "accept: application/json" -d '{"filters": { "notify": { "body" : "message body", "subject": "message subject" } }}' -X GET "http://[rails_host]/v1/steps/290/notify?token=[api_token]" --header "Content-Type: application/json"
  # curl -i -H "accept: text/xml" -H "Content-type: text/xml"  -d '<filters><notify><recipients>recipients@rr.com, recispients@rr.com</recipients><body>message body</body><subject>message subject</subject></notify></filters>' -X GET "http://localhost:3000/v1/steps/290/notify?token=74a40011c791c0a1329444a53bd33bfd0b08b990"

  def notify
    @step =  Step.find(params[:id].to_i) rescue nil
    if @step.present? && params[:filters][:notify]
      Notifier.delay.step_notify_mail(@step.id, params[:filters][:notify])
      head :ok, content_type: 'text/html'
    else
      head :bad_request, content_type: 'text/html'
    end
  end

  # Creates a new step from a posted XML document
  #
  # ==== Attributes
  #
  # * +id+ - numerical unique id for record to be updated
  # * +step with name+ - string name of the step (required)
  # * +step with step_template_id+ - integer of an existing step template id (required)
  # * +step with release_name+ - will trigger a look up for an existing release by that name or return an error if not found
  # * +step with step_template_name+ - will trigger a lookup for an existing step template by that name or return an error if not found  
  # * +step ... + - other valid step fields
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Accepts Nested Attributes for Creation and Update of Associated Objects
  #
  # * +step with release_attributes - this will accept nested attributes for an existing or a new release
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<step><name>XML Step</name><release_name>Sample Release</release_name>  <step_template>Sample Deploy Template</step_template></step>'  http://0.0.0.0:3000/v1/steps?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d \n '{ "step": { "name" : "JSONRenamedStep", "step_template_id":1}}'  http://[rails_host]/v1/steps?token=[api_token]
  #
  # Create a new step and a new associated release
  #
  #    curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d '<step><name>XML Step 3:05PM</name><release_attributes><name>Brand New Release 2</name></release_attributes><step_template_id>1</step_template_id></step>' http://0.0.0.0:3000/v1/steps?token=[token]
  
  def create
    @step = Step.new
    respond_to do |format|
      begin
        success = @step.update_attributes(params[:step])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => step_presenter, :status => :created }
        format.json  { render :json => step_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @step.errors, :status => :unprocessable_entity }
        format.json  { render :json => @step.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing step with values from a posted XML document
  #
  # ==== Attributes
  #
  # * +step with other fields+ - other valid step fields
  # * +step with release_name+ - will trigger a look up for an existing release by that name or return an error if not found
  # * +step with step_template_name+ - will trigger a lookup for an existing step template by that name or return an error if not found
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<step><name>XML Step</name><release_name>Sample Release</release_name></step>' http://0.0.0.0:3000/v1/steps/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "step": { "name" : "JSONRenamedStep", "description":"JSON Hello"}}'  http://[rails_host]/v1/steps/[id]?token=[api_token] 
  def update
    @step = Step.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @step
        begin
          success = @step.update_attributes(params[:step])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => step_presenter, :status => :accepted }
          format.json  { render :json => step_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @step.errors, :status => :unprocessable_entity }
          format.json  { render :json => @step.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Deletes a step
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/steps/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/steps/[id]?token=[api_token]
  def destroy
    @step = Step.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @step
        success = @step.try(:destroy) rescue false
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => step_presenter, :status => :precondition_failed }
          format.json { render :json => step_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end
  
  private

  # helper for loading the steps presenter
  def steps_presenter
    @steps_presenter ||= V1::StepsPresenter.new(@steps, @template)
  end
    
  # helper for loading the step present  
  def step_presenter
    @step_presenter ||= V1::StepPresenter.new(@step, @template)
  end
  
end
