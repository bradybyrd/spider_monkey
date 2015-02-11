class V1::NotificationTemplatesController < V1::AbstractRestController
  # Returns notification_templates that are unarchived by default
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/notification_templates?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/notification_templates?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><name>Sample Template</name></filters>' http://[rails_host]/v1/notification_templates?token=[api_token]
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "name" : 'Sample Template' }}' -X GET http://[rails_host]/v1/notification_templates?token=[api_token]
  def index
    @notification_templates = NotificationTemplate.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @notification_templates.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => notification_templates_presenter }
        format.json { render :json => notification_templates_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a notification_template by notification_template id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/notification_templates/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/notification_templates/[id]?token=[api_token]
  def show
    @notification_template = NotificationTemplate.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @notification_template.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => notification_template_presenter }
        format.json { render :json => notification_template_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new notification_template from a post request
  #
  # ==== Attributes
  #
  # * +title+ - string title of the notification_template (required, unique)
  # * +event+ - string event for notification_template (required, one of [exception_raised request_message request_completed request_cancelled step_started step_ready step_completed step_blocked step_problem user_created password_reset password_changed login user_admin_created])
  # * +format+ - string format for notification_template (required, one of [text/plain, text/enriched, text/html])
  # * +body+ - text of the message in liquid template format (required)
  # * +description+ - string description of the notification template
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<notification_template><title>XML NotificationTemplate</title><event>exception_raised</event><format>text/html</format><body>Test Template</body></notification_template>'  http://[rails_host]/v1/notification_templates?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "notification_template": { "title" : "JSON Template", "format":"text/html", "event":"exception_raised", "body":"Test Body" }}'  http://[rails_host]/v1/notification_templates?token=[api_token]

  def create
    @notification_template = NotificationTemplate.new
    respond_to do |format|
      begin
        success = @notification_template.update_attributes(params[:notification_template])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => notification_template_presenter, :status => :created }
        format.json  { render :json => notification_template_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @notification_template.errors, :status => :unprocessable_entity }
        format.json  { render :json => @notification_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing notification_template with values from a PUT request
  #
  # ==== Attributes
  #
  # * +title+ - string title of the notification_template (required, unique)
  # * +event+ - string event for notification_template (required, one of [exception_raised request_message request_completed request_cancelled step_started step_ready step_completed step_blocked step_problem user_created password_reset password_changed login user_admin_created])
  # * +format+ - string format for notification_template (required, one of [text/plain, text/enriched, text/html])
  # * +body+ - text of the message in liquid template format (required)
  # * +description+ - string description of the notification template
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<notification_template><name>XML NotificationTemplate</name></notification_template>' http://[rails_host]/v1/notification_templates/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "notification_template": { "name" : "JSONRenamedNotificationTemplate" }}'  http://[rails_host]/v1/notification_templates/[id]?token=[api_token]
  def update
    @notification_template = NotificationTemplate.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @notification_template
        begin
          success = @notification_template.update_attributes(params[:notification_template])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => notification_template_presenter, :status => :accepted }
          format.json  { render :json => notification_template_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @notification_template.errors, :status => :unprocessable_entity }
          format.json  { render :json => @notification_template.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a notification_template by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/notification_templates/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/notification_templates/[id]?token=[api_token]
  def destroy
    @notification_template = NotificationTemplate.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @notification_template
        success = @notification_template.try(:deactivate!) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => notification_template_presenter, :status => :precondition_failed }
          format.json { render :json => notification_template_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the notification_templates presenter
  def notification_templates_presenter
    @notification_templates_presenter ||= V1::NotificationTemplatesPresenter.new(@notification_templates, @template)
  end

  # helper for loading the notification_template present
  def notification_template_presenter
    @notification_template_presenter ||= V1::NotificationTemplatePresenter.new(@notification_template, @template)
  end
end
