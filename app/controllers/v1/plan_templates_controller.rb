class V1::PlanTemplatesController < V1::AbstractRestController
  include ObjectStateController
  # Returns plan_templates that are not deleted nor archived
  #
  # ==== Attributes
  #
  # * +filters+ - Filters criteria for getting subset of installed_components, can be - "name (String)", "archived (Boolean)"  
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/plan_templates?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/plan_templates?token=[api_token]
  #
  # Filter example
  #
  #   curl -i -H "accept: application/json" -X GET -d '{ "filters": { "name":"Sample Plan Template Name" }}' http://[rails_host]/v1/plan_templates?token=[api_token]
  def index
    @plan_templates = PlanTemplate.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @plan_templates.try(:empty?)
        format.xml { render :xml => plan_templates_presenter }
        format.json { render :json => plan_templates_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a plan_template by plan_template id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/plan_templates/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/plan_templates/[id]?token=[api_token]

  def show
    @plan_template = PlanTemplate.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @plan_template.blank?
        format.xml { render :xml => plan_template_presenter }
        format.json { render :json => plan_template_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new plan_template from a posted XML document
  #
  # ==== Attributes
  #
  # * +id+ - numerical unique id for record to be updated
  # * +plan_template[name]+ - string name of the plan_template (required)
  # * +plan_template[plan_template_type]+ - string of a valid template type
  # * +plan_template[...]+ - other valid plan_template fields
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
  #   curl -i -H "accept: text/xml" -X POST -d "plan_template[name]=TestPlan&plan_template[plan_template_type=deploy&token=[...your token...]" http://[rails_host]/v1/plan_templates
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "plan_template": { "name" : "JSONRenamedPlan", "plan_template_id":1}}' http://[rails_host]/v1/plan_templates/[id]?token=[api_token]
  def create
    @plan_template = PlanTemplate.new
    respond_to do |format|
      begin
        success = @plan_template.update_attributes(params[:plan_template])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => plan_template_presenter, :status => :created }
        format.json  { render :json => plan_template_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @plan_template.errors, :status => :unprocessable_entity }
        format.json  { render :json => @plan_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing plan_template with values from a posted XML document
  #
  # ==== Attributes
  #
  # * +plan_template[...]+ - other valid plan_template fields
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
  #   curl -i -H "accept: text/xml" -X PUT -d "plan_template[name]=NewName&plan_template[plan_template_type]=Hello&token=[...your token...]" http://[rails_host]/v1/plan_templates/[id]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "plan_template": { "name" : "JSONRenamedPlan", "description":"JSON Hello"}}'  http://[rails_host]/v1/plan_templates/[id]
  def update
    @plan_template = PlanTemplate.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @plan_template
        begin
          # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @plan_template.toggle_archive
            @plan_template.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
          elsif params[:plan_template].present?
            success = @plan_template.update_attributes_with_state(params[:plan_template])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => plan_template_presenter, :status => :accepted }
          format.json  { render :json => plan_template_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @plan_template.errors, :status => :unprocessable_entity }
          format.json  { render :json => @plan_template.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Deletes a plan template
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/plan_templates/[id].xml?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/plan_templates/[id].xml?token=[api_token]
  def destroy
    @plan_template = PlanTemplate.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @plan_template
        success = @plan_template.destroy rescue false
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => plan_template_presenter, :status => :precondition_failed }
          format.json { render :json => plan_template_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end
  
  private

  # helper for loading the plan_templates presenter
  def plan_templates_presenter
    @plan_templates_presenter ||= V1::PlanTemplatesPresenter.new(@plan_templates, @template)
  end

  # helper for loading the plan_template present
  def plan_template_presenter
    @plan_template_presenter ||= V1::PlanTemplatePresenter.new(@plan_template, @template)
  end

end
