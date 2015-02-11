class V1::ReleasesController < V1::AbstractRestController
  
  # Returns releases that are not deleted nor archived
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/releases?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/releases?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><name>February Release</name></filters>' http://[rails_host]/v1/releases?token=[api_token]
  #
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "name" : ["February Release"] }}' -X GET http://[rails_host]/v1/releases?token=[api_token] d
  def index
    @releases = Release.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @releases.try(:empty?)
        format.xml { render :xml => releases_presenter }
        format.json { render :json => releases_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a release by release id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/releases/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/releases/[id]?token=[api_token]
  def show
    @release = Release.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @release.blank?
        format.xml { render :xml => release_presenter }
        format.json { render :json => release_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new release from a posted XML document
  #
  # ==== Attributes
  #
  # * +name+ - string name (required)
  # * +integration_project_id+ - integer id of the integration project
  # * +request_ids+ - array of integer ids of associated requests
  # * +plan_ids+ - array of integer ids of associated plans
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Accepts Nested Attributes for Creation and Update of Associated Objects
  #
  # * +release with release_attributes - this will accept nested attributes for an existing or a new release
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<release><name>XML Release</name><release_name>Sample Release</release_name>  <release_template>Sample Deploy Template</release_template></release>'  http://[rails_host]/v1/releases?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d \n '{ "release": { "name" : "JSONRenamedRelease", "release_template_id":1}}'  http://[rails_host]/v1/releases?token=[api_token]
  #
  # Create a new release and a new associated release
  #
  #    curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d '<release><name>XML Release 3:05PM</name><release_attributes><name>Brand New Release 2</name></release_attributes><release_template_id>1</release_template_id></release>' http://[rails_host]/v1/releases?token=[token]
  
  def create
    @release = Release.new
    respond_to do |format|
      begin
        success = @release.update_attributes(params[:release])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => release_presenter, :status => :created }
        format.json  { render :json => release_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @release.errors, :status => :unprocessable_entity }
        format.json  { render :json => @release.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing release with values from a posted XML document
  #
  # ==== Attributes
  #
  # * +name+ - string name (required)
  # * +integration_project_id+ - integer id of the integration project
  # * +request_ids+ - array of integer ids of associated requests
  # * +plan_ids+ - array of integer ids of associated plans
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<release><name>XML Release</name></release>' http://[rails_host]/v1/releases/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "release": { "name" : "JSONRenamedRelease"}}'  http://[rails_host]/v1/releases/[id]?token=[api_token] 
  def update
    @release = Release.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @release
        begin
          # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @release.toggle_archive
            @release.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
            # otherwise continue on with a standard update
          elsif params[:release].present?
            success = @release.update_attributes(params[:release])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => release_presenter, :status => :accepted }
          format.json  { render :json => release_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @release.errors, :status => :unprocessable_entity }
          format.json  { render :json => @release.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Deletes a release
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/releases/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/releases/[id]?token=[api_token]
  def destroy
    @release = Release.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @release
        success = @release.try(:destroy) rescue false
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => release_presenter, :status => :precondition_failed }
          format.json { render :json => release_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end
  
  private

  # helper for loading the releases presenter
  def releases_presenter
    @releases_presenter ||= V1::ReleasesPresenter.new(@releases, @template)
  end
    
  # helper for loading the release present  
  def release_presenter
    @release_presenter ||= V1::ReleasePresenter.new(@release, @template)
  end
  
end
