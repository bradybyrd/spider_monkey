class V1::RequestTemplatesController < V1::AbstractRestController
  # Returns request_templates that are unarchived by default
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  # * +filters+ - archived:boolean, unarchived:boolean, name:string
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/request_templates?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/request_templates?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><name>Sample RequestTemplate</name></filters>' http://[rails_host]/v1/request_templates?token=[api_token]
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "name" : 'Sample RequestTemplate' }}' -X GET http://[rails_host]/v1/request_templates?token=[api_token]
  def index
    @request_templates = RequestTemplate.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @request_templates.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => request_templates_presenter }
        format.json { render :json => request_templates_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a request_template by request_template id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/request_templates/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/request_templates/[id]?token=[api_token]
  def show
    @request_template = RequestTemplate.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @request_template.present?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => request_template_presenter }
        format.json { render :json => request_template_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new request_template from a post request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the request_template (required, unique)
  # * +property_ids+ - array of integer ids for related properties
  # * +step_ids+ - array of integer ids for related step ids
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<work-task><name>XML RequestTemplate 2</name></work-task>'  http://[rails_host]/v1/request_templates?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{"request_template": {"name":"RequestTemplate New" }}'  http://[rails_host]/v1/request_templates?token=[api_token]

  def create
    @request_template = RequestTemplate.new
    respond_to do |format|
      begin
        success = @request_template.update_attributes(params[:request_template])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => request_template_presenter, :status => :created }
        format.json  { render :json => request_template_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @request_template.errors, :status => :unprocessable_entity }
        format.json  { render :json => @request_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing request_template with values from a PUT request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the request_template (required, unique)
  # * +property_ids+ - array of integer ids for related properties
  # * +step_ids+ - array of integer ids for related step ids
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Toggle Archival Status
  #
  # * +toggle_archive+ - boolean that will toggle the archive status of an object
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<work-task><name>XML RequestTemplate Rename</name></work-task>' http://[rails_host]/v1/request_templates/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "request_template": { "name" : "JSON RequestTemplate Rename" }}'  http://[rails_host]/v1/request_templates/[id]?token=[api_token]
  def update
    @request_template = RequestTemplate.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @request_template
        begin
          # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @request_template.toggle_archive
            @request_template.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
          elsif params[:request_template].present?
            success = @request_template.update_attributes_with_state(params[:request_template])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => request_template_presenter, :status => :accepted }
          format.json  { render :json => request_template_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @request_template.errors, :status => :unprocessable_entity }
          format.json  { render :json => @request_template.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a request_template by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/request_templates/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/request_templates/[id]?token=[api_token]
  def destroy
    @request_template = RequestTemplate.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @request_template
        success = @request_template.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => request_template_presenter, :status => :precondition_failed }
          format.json { render :json => request_template_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the request_templates presenter
  def request_templates_presenter
    @request_templates_presenter ||= V1::RequestTemplatesPresenter.new(@request_templates, @template)
  end

  # helper for loading the request_template present
  def request_template_presenter
    @request_template_presenter ||= V1::RequestTemplatePresenter.new(@request_template, @template)
  end
end
