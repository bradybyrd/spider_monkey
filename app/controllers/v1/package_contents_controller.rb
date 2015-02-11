class V1::PackageContentsController < V1::AbstractRestController
  # Returns package_contents that are unarchived by default
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/package_contents?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/package_contents?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><name>Sample PackageContent</name></filters>' http://[rails_host]/v1/package_contents?token=[api_token]
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "name" : 'Sample PackageContent' }}' -X GET http://[rails_host]/v1/package_contents?token=[api_token]
  def index
    @package_contents = PackageContent.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @package_contents.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => package_contents_presenter }
        format.json { render :json => package_contents_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a package_content by package_content id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/package_contents/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/package_contents/[id]?token=[api_token]
  def show
    @package_content = PackageContent.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @package_content.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => package_content_presenter }
        format.json { render :json => package_content_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new package_content from a post request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the package_content (required, unique)
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<package-content><name>XML PackageContent 2</name></package-content>'  http://[rails_host]/v1/package_contents?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{"package_content": {"name":"PackageContent New" }}'  http://[rails_host]/v1/package_contents?token=[api_token]

  def create
    @package_content = PackageContent.new
    respond_to do |format|
      begin
        success = @package_content.update_attributes(params[:package_content])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => package_content_presenter, :status => :created }
        format.json  { render :json => package_content_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @package_content.errors, :status => :unprocessable_entity }
        format.json  { render :json => @package_content.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing package_content with values from a PUT request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the package_content (required, unique)
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<package-content><name>XML PackageContent Rename</name></package-content>' http://[rails_host]/v1/package_contents/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "package_content": { "name" : "JSON PackageContent Rename" }}'  http://[rails_host]/v1/package_contents/[id]?token=[api_token]
  def update
    @package_content = PackageContent.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @package_content
        begin
          # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @package_content.toggle_archive
            @package_content.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
            # otherwise continue on with a standard update  
          elsif params[:package_content].present?
            success = @package_content.update_attributes(params[:package_content])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => package_content_presenter, :status => :accepted }
          format.json  { render :json => package_content_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @package_content.errors, :status => :unprocessable_entity }
          format.json  { render :json => @package_content.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a package_content by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/package_contents/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/package_contents/[id]?token=[api_token]
  def destroy
    @package_content = PackageContent.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @package_content
        success = @package_content.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => package_content_presenter, :status => :precondition_failed }
          format.json { render :json => package_content_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the package_contents presenter
  def package_contents_presenter
    @package_contents_presenter ||= V1::PackageContentsPresenter.new(@package_contents, @template)
  end

  # helper for loading the package_content present
  def package_content_presenter
    @package_content_presenter ||= V1::PackageContentPresenter.new(@package_content, @template)
  end
end
