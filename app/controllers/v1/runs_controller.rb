class V1::RunsController < V1::AbstractRestController
  # Returns runs that are not deleted nor archived
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  # * +filters+ - aasm_state, stage_id, owner_id, requestor_id, started_at, end_at, time (any datetime between start and end inclusive)
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 404 Not Found - When no records are found.
  #
  # ==== Examples test
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/runs?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/runs?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><aasm_state>created</aasm_state><aasm_state>planned</aasm_state></filters>' http://[rails_host]/v1/runs?token=[api_token]
  #
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "aasm_state" : ["created","planned"] }}' -X GET http://[rails_host]/v1/runs?token=[api_token] d
  def index
    @runs = Run.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @runs.try(:empty?)
        format.xml { render :xml => runs_presenter }
        format.json { render :json => runs_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a run by run id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/runs/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/runs/[id]?token=[api_token]
  def show
    @run = Run.not_deleted.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @run.blank?
        format.xml { render :xml => run_presenter }
        format.json { render :json => run_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new run from a posted XML document
  #
  # ==== Attributes
  #
  # * +name+ - string name of the run (required)
  # * +plan_id - id of related plan (required)
  # * +plan_stage_id - id of related plan_stage (required)
  # * +owner_id - id of User that owns the run (required)
  # * +requestor_id - id of User that requested the run (required)
  # * +run ... + - other valid run fields
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<run><name>XML Run</name><plan_id>1</plan_id><plan_stage_id>1</plan_stage_id><owner_id>1</owner_id><requestor_id>1</requestor_id></run>'  http://[rails_host]/v1/runs?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "run": { "name" : "JSON Sample Run", "plan_id":1, "plan_stage_id":1, "owner_id":1, "requestor_id":1}}'  http://0.0.0.0:3000/v1/runs?token=44d5d3b36a0b57643114256a62a7312e508259f2
  #

  def create
    @run = Run.new
    respond_to do |format|
      begin
        success = @run.update_attributes(params[:run])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => run_presenter, :status => :created }
        format.json  { render :json => run_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @run.errors, :status => :unprocessable_entity }
        format.json  { render :json => @run.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing run with values from a posted XML document
  #
  # ==== Attributes
  #
  # * +run with other fields+ - other valid run fields
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Events
  #
  # * +aasm_event+ - can be submitted to transition a run to the next state.  Supported events: plan_it, start, hold, block, cancel, complete, delete.
  #     curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d  '<run aasm-event-command="plan"></run>'  http://[rails_host]/v1/runs/[id]?token=[api_token]
  #     curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "run": { "aasm_event" : "plan" }}'  http://[rails_host]/v1/runs/[id]?token=[api_token]
  #
  # * +Note: XML requires hyphens and JSON requires underscores for this property name.+
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<run><name>XML Run</name><release_name>Sample Release</release_name></run>' http://[rails_host]/v1/runs/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "run": { "name" : "JSONRenamedRun", "description":"JSON Hello"}}'  http://[rails_host]/v1/runs/[id]?token=[api_token]
  def update
    @run = Run.not_deleted.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @run
        begin
          success = @run.update_attributes(params[:run])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => run_presenter, :status => :accepted }
          format.json  { render :json => run_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @run.errors, :status => :unprocessable_entity }
          format.json  { render :json => @run.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a run by setting its aasm_state to "deleted" and removing it from default displays
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/runs/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/runs/[id]?token=[api_token]
  def destroy
    @run = Run.not_deleted.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @run
        success = @run.try(:delete!) rescue false
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => run_presenter, :status => :precondition_failed }
          format.json { render :json => run_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the runs presenter
  def runs_presenter
    @runs_presenter ||= V1::RunsPresenter.new(@runs, @template)
  end

  # helper for loading the run present
  def run_presenter
    @run_presenter ||= V1::RunPresenter.new(@run, @template)
  end

end
