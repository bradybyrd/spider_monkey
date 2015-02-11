class V1::CategoriesController < V1::AbstractRestController
  # Returns categories that are unarchived by default
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/categories?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/categories?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><name>Sample Category</name></filters>' http://[rails_host]/v1/categories?token=[api_token]
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "name" : 'Sample Category' }}' -X GET http://[rails_host]/v1/categories?token=[api_token]
  def index
    @categories = Category.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @categories.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => categories_presenter }
        format.json { render :json => categories_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a category by category id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/categories/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/categories/[id]?token=[api_token]
  def show
    @category = Category.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @category.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => category_presenter }
        format.json { render :json => category_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new category from a post request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the category (required, unique)
  # * +categorized_type+ - string type for the category (request, step) (required)
  # * +associated_events+ - comma delimited list of eligible step state machine events (problem, resolve, cancel) for category (required)
  # * +step_ids+ - array of integer ids for related steps
  # * +request_ids+ - array of integer ids for related request ids
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<category><name>XML Category 2</name><associated-events>problem</associated-events><associated-events>resolve</associated-events><categorized-type>request</categorized-type></category>'  http://[rails_host]/v1/categories?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{"category": {"name":"Category New", "associated_events":["problem","resolve"], "categorized_type":"request" }}'  http://[rails_host]/v1/categories?token=[api_token]

  def create
    @category = Category.new
    respond_to do |format|
      begin
        success = @category.update_attributes(params[:category])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => category_presenter, :status => :created }
        format.json  { render :json => category_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
        format.json  { render :json => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing category with values from a PUT request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the category (required, unique)
  # * +categorized_type+ - string type for the category (request, step) (required)
  # * +associated_events+ - comma delimited list of eligible step state machine events (problem, resolve, cancel) for category (required)
  # * +step_ids+ - array of integer ids for related steps
  # * +request_ids+ - array of integer ids for related request ids
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<category><name>XML Category Rename</name></category>' http://[rails_host]/v1/categories/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "category": { "name" : "JSON Category Rename" }}'  http://[rails_host]/v1/categories/[id]?token=[api_token]
  def update
    @category = Category.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @category
        begin
          # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @category.toggle_archive
            @category.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
            # otherwise continue on with a standard update  
          elsif params[:category].present?
            success = @category.update_attributes(params[:category])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => category_presenter, :status => :accepted }
          format.json  { render :json => category_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
          format.json  { render :json => @category.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a category by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/categories/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/categories/[id]?token=[api_token]
  def destroy
    @category = Category.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @category
        success = @category.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => category_presenter, :status => :precondition_failed }
          format.json { render :json => category_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the categories presenter
  def categories_presenter
    @categories_presenter ||= V1::CategoriesPresenter.new(@categories, @template)
  end

  # helper for loading the category present
  def category_presenter
    @category_presenter ||= V1::CategoryPresenter.new(@category, @template)
  end
end
