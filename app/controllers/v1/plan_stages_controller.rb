class V1::PlanStagesController < V1::AbstractRestController
  # Returns plan_stages that are not deleted nor archived
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/plan_stages?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/plan_stages?token=[api_token]
  def index
    @plan_stages = PlanStage.all rescue nil
    respond_to do |format|
      unless @plan_stages.try(:empty?)
        format.xml { render :xml => plan_stages_presenter }
        format.json { render :json => plan_stages_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a plan_stage by plan_stage id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/plan_stages/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/plan_stages/[id]?token=[api_token]

  def show
    @plan_stage = PlanStage.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @plan_stage.blank?
        format.xml { render :xml => plan_stage_presenter }
        format.json { render :json => plan_stage_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new plan_stage from a posted XML document
  #
  # ==== Attributes
  #
  # * +id+ - numerical unique id for record to be updated
  # * +plan_stage[name]+ - string name of the plan_stage (required)
  # * +plan_stage[plan_template_id]+ - string of a valid template type
  # * +plan_stage[...]+ - other valid plan_stage fields
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
  #   curl -i -H "accept: text/xml" -X POST -d "plan_stage[name]=TestPlan&plan_stage[plan_template_id]=3&token=[...your token...]" http://[rails_host]/v1/plan_stages
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "plan_stage": { "name" : "JSONRenamedPlan", "plan_template_id":3}}' http://[rails_host]/v1/plan_stages/[id]?token=[api_token]
  def create
    @plan_stage = PlanStage.new
    respond_to do |format|
      begin
        success = @plan_stage.update_attributes(params[:plan_stage])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => plan_stage_presenter, :status => :created }
        format.json  { render :json => plan_stage_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @plan_stage.errors, :status => :unprocessable_entity }
        format.json  { render :json => @plan_stage.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing plan_stage with values from a posted XML document
  #
  # ==== Attributes
  #
  # * +plan_stage[...]+ - other valid plan_stage fields
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
  #   curl -i -H "accept: text/xml" -X PUT -d "plan_stage[name]=NewName&plan_stage[plan_template_id]=3&token=[...your token...]" http://[rails_host]/v1/plan_stages/[id]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "plan_stage": { "name" : "JSONRenamedPlan", "plan_template_id":3}}'  http://[rails_host]/v1/plan_stages/[id]
  def update
    @plan_stage = PlanStage.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @plan_stage
        begin
          success = @plan_stage.update_attributes(params[:plan_stage])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => plan_stage_presenter, :status => :accepted }
          format.json  { render :json => plan_stage_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @plan_stage.errors, :status => :unprocessable_entity }
          format.json  { render :json => @plan_stage.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Deletes a plan stage
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/plan_stages/[id].xml?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/plan_stages/[id].xml?token=[api_token]
  def destroy
    @plan_stage = PlanStage.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @plan_stage
        success = @plan_stage.destroy rescue false
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => plan_stage_presenter, :status => :precondition_failed }
          format.json { render :json => plan_stage_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end
  
    
  private

  # helper for loading the plan_stages presenter
  def plan_stages_presenter
    @plan_stages_presenter ||= V1::PlanStagesPresenter.new(@plan_stages, @template)
  end

  # helper for loading the plan_stage present
  def plan_stage_presenter
    @plan_stage_presenter ||= V1::PlanStagePresenter.new(@plan_stage, @template)
  end

end
