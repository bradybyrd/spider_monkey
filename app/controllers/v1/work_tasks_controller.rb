class V1::WorkTasksController < V1::AbstractRestController
  # Returns work_tasks that are unarchived by default
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/work_tasks?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/work_tasks?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><name>Sample WorkTask</name></filters>' http://[rails_host]/v1/work_tasks?token=[api_token]
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "name" : 'Sample WorkTask' }}' -X GET http://[rails_host]/v1/work_tasks?token=[api_token]
  def index
    @work_tasks = WorkTask.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @work_tasks.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => work_tasks_presenter }
        format.json { render :json => work_tasks_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a work_task by work_task id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/work_tasks/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/work_tasks/[id]?token=[api_token]
  def show
    @work_task = WorkTask.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @work_task.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => work_task_presenter }
        format.json { render :json => work_task_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new work_task from a post request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the work_task (required, unique)
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<work-task><name>XML WorkTask 2</name></work-task>'  http://[rails_host]/v1/work_tasks?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{"work_task": {"name":"WorkTask New" }}'  http://[rails_host]/v1/work_tasks?token=[api_token]

  def create
    @work_task = WorkTask.new
    respond_to do |format|
      begin
        success = @work_task.update_attributes(params[:work_task])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => work_task_presenter, :status => :created }
        format.json  { render :json => work_task_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @work_task.errors, :status => :unprocessable_entity }
        format.json  { render :json => @work_task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing work_task with values from a PUT request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the work_task (required, unique)
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<work-task><name>XML WorkTask Rename</name></work-task>' http://[rails_host]/v1/work_tasks/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "work_task": { "name" : "JSON WorkTask Rename" }}'  http://[rails_host]/v1/work_tasks/[id]?token=[api_token]
  def update
    @work_task = WorkTask.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @work_task
        begin
          # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @work_task.toggle_archive
            @work_task.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
            # otherwise continue on with a standard update  
          elsif params[:work_task].present?
            success = @work_task.update_attributes(params[:work_task])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => work_task_presenter, :status => :accepted }
          format.json  { render :json => work_task_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @work_task.errors, :status => :unprocessable_entity }
          format.json  { render :json => @work_task.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a work_task by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/work_tasks/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/work_tasks/[id]?token=[api_token]
  def destroy
    @work_task = WorkTask.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @work_task
        success = @work_task.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => work_task_presenter, :status => :precondition_failed }
          format.json { render :json => work_task_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the work_tasks presenter
  def work_tasks_presenter
    @work_tasks_presenter ||= V1::WorkTasksPresenter.new(@work_tasks, @template)
  end

  # helper for loading the work_task present
  def work_task_presenter
    @work_task_presenter ||= V1::WorkTaskPresenter.new(@work_task, @template)
  end
end
