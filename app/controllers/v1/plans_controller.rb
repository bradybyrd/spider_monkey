class V1::PlansController < V1::AbstractRestController
  # Returns plans that are not deleted nor archived
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  # * +filters+ - aasm_state, plan_template_type, plan_template_id, stage_id, release_id, release_date, release_manager_id, team_id, app_id, environment_id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/plans?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/plans?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><aasm_state>created</aasm_state><aasm_state>planned</aasm_state></filters>' http://[rails_host]/v1/plans?token=[api_token]
  #
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X GET -d '{ "filters": { "aasm_state" : ["created","planned"] }}' http://[rails_host]/v1/plans?token=[api_token]
  def index
    @plans = Plan.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @plans.try(:empty?)
        format.xml { render :xml => plans_presenter }
        format.json { render :json => plans_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a plan by plan id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/plans/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/plans/[id]?token=[api_token]
  def show
    @plan = Plan.not_deleted.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @plan.blank?
        format.xml { render :xml => plan_presenter }
        format.json { render :json => plan_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new plan from a posted XML document
  #
  # ==== Attributes
  #
  # * +name+ - string name of the plan (required)
  # * +plan_template_id+ - integer value of an existing plan template id (required if plan_template_name lookup not used)
  # * +plan_template_name+ - will trigger a lookup for an existing plan template by that name or return an error if not found
  # * +release_id+ - integer value of an existing release id (optional, alternate to release_name lookup if id is known)
  # * +release_name+ - will trigger a look up for an existing release by that name or return an error if not found
  # * +release_manager_id+ - integer id of the associated user assigned as release manager
  # * +release_date+ - string date for the release date
  # * +description+ - string for descriptive text
  # * +team_ids+ - array of integer ids for associated teams
  # * +release_attributes+ - nested attributes for updating or creating an associated release (properties include 'name')
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Accepts Nested Attributes for Creation and Update of Associated Objects
  #
  # * +plan with release_attributes - this will accept nested attributes for an existing or a new release
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<plan><name>XML Plan</name><release_name>Sample Release</release_name>  <plan_template>Sample Deploy Template</plan_template></plan>'  http://[rails_host]/v1/plans?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d \n '{ "plan": { "name" : "JSONRenamedPlan", "plan_template_id":1}}'  http://[rails_host]/v1/plans?token=[api_token]
  #
  # Create a new plan and a new associated release
  #
  #    curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d '<plan><name>XML Plan 3:05PM</name><release_attributes><name>Brand New Release 2</name></release_attributes><plan_template_id>1</plan_template_id></plan>' http://[rails_host]/v1/plans?token=[token]

  def create
    @plan = Plan.new
    respond_to do |format|
      begin
        success = @plan.update_attributes(params[:plan])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => plan_presenter, :status => :created }
        format.json  { render :json => plan_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @plan.errors, :status => :unprocessable_entity }
        format.json  { render :json => @plan.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing plan with values from a posted XML document
  #
  # ==== Attributes
  #
  # * +name+ - string name of the plan (required)
  # * +plan_template_id+ - integer value of an existing plan template id (required if plan_template_name lookup not used)
  # * +plan_template_name+ - will trigger a lookup for an existing plan template by that name or return an error if not found
  # * +release_id+ - integer value of an existing release id (optional, alternate to release_name lookup if id is known)
  # * +release_name+ - will trigger a look up for an existing release by that name or return an error if not found
  # * +release_manager_id+ - integer id of the associated user assigned as release manager
  # * +release_date+ - string date for the release date
  # * +description+ - string for descriptive text
  # * +team_ids+ - array of integer ids for associated teams
  # * +release_attributes+ - nested attributes for updating or creating an associated release (properties include 'name')
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Events
  #
  # * +aasm_event+ - can be submitted to transition a plan to the next state.  Supported events: plan_it, start, lock, finish, archive, put_on_hold, cancel
  #     curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d  '<plan aasm-event-command="plan"></plan>'  http://[rails_host]/v1/plans/[id]?token=[api_token]
  #     curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "plan": { "aasm_event" : "plan" }}'  http://[rails_host]/v1/plans/[id]?token=[api_token]
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<plan><name>XML Plan</name><release_name>Sample Release</release_name></plan>' http://[rails_host]/v1/plans/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "plan": { "name" : "JSONRenamedPlan", "description":"JSON Hello"}}'  http://[rails_host]/v1/plans/[id]?token=[api_token]
  def update
    @plan = Plan.not_deleted.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @plan
        begin
          success = @plan.update_attributes(params[:plan])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => plan_presenter, :status => :accepted }
          format.json  { render :json => plan_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @plan.errors, :status => :unprocessable_entity }
          format.json  { render :json => @plan.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a plan by setting its aasm_state to "deleted" and removing it from default displays
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/plans/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/plans/[id]?token=[api_token]
  def destroy
    @plan = Plan.not_deleted.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @plan
        success = @plan.try(:delete!) rescue false
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => plan_presenter, :status => :precondition_failed }
          format.json { render :json => plan_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the plans presenter
  def plans_presenter
    @plans_presenter ||= V1::PlansPresenter.new(@plans, @template)
  end

  # helper for loading the plan present
  def plan_presenter
    @plan_presenter ||= V1::PlanPresenter.new(@plan, @template)
  end

end
