class V1::VersionTagsController < V1::AbstractRestController
  
  # Returns version_tags that are not deleted nor archived
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  # * +filters+ - Filters criteria for getting subset of version_tags, can be - "app_name", "component_name", "environment_name" or "name"
  #  
  # * Note: app_name can be searched using a prefix if the delimiter '_|_' is used in the application name.  For example, searching for 
  # 'BRPM' will find installed components associated with 'BRPM_|_BMC Release Process Management'.
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/version_tags?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/version_tags?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><application_name>App 1</application_name><component_name>AppServer</component_name></filters>' http://[rails_host]/v1/version_tags?token=[api_token]
  #
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X GET -d '{ "filters": { "application_name" : "App 1", "component_name" : "AppServer" }}' http://[rails_host]/v1/version_tags?token=[api_token]
  #
  def index
    @version_tags = VersionTag.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @version_tags.try(:empty?)
        # to provide a version_tag specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => version_tags_presenter }
        format.json { render :json => version_tags_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a version_tag by version_tag id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/version_tags/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/version_tags/[id]?token=[api_token]
  def show
    @version_tag = VersionTag.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @version_tag.blank?
        # to provide a version_tag specific and secure representation of an object, wrap it in a presenter
        
        format.xml { render :xml => version_tag_presenter }
        format.json { render :json => version_tag_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new version_tag from a posted XML document
  #
  # ==== Attributes
  #
  # * +name+ - string version_tag (required)
  # * +find_application+ - application name (required)
  # * +find_component+ - component name
  # * +find_environment+ - environment name  
  # * +artifact_url+ - artifact url
  # * +active+ - is active?
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # * Note: find_application can be searched using a prefix if the delimiter '_|_' is used in the application name.  For example, searching for 
  # 'BRPM' will find installed components associated with 'BRPM_|_BMC Release Process Management'.
  #
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  
  #      '<version_tag>
  #           <name>v4.0.1.4_b</name>
  #           <find_application>Abinitio</find_application>
  #           <find_component>AppServer</find_component>
  #           <find_environment>PreProd</find_environment>
  #           <artifact_url>http://dml/appserver/ver4.0.1.4</artifact_url>
  #           <active>true</active>
  #       </version_tag>'
  #       http://0.0.0.0:3000/v1/version_tags?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d \n 
  #      '{"version_tag":
  #          {   
  #           "name":"v4.0.1.4_b",
  #           "find_application":"Abinitio",
  #           "find_component":"AppServer",
  #           "find_environment":"PreProd"
  #           "artifact_url":"http://dml/appserver/ver4.0.1.4",
  #           "active":true
  #          }
  #        }
  #       http://[rails_host]/v1/version_tags?token=[api_token]
  #
  # Alternatively, you may put the version data into a text file and pass the filename as argument to the curl command:
  #   
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d @create_version.xml http://0.0.0.0:3000/v1/version_tags?token=[api_token]
  #
  # Creates a new version_tag and associates with the application/environment/installed component
  #
    
  def create
    @version_tag = VersionTag.new
    success = false
    respond_to do |format|
      begin
        success = @version_tag.update_from_params(params[:version_tag], true)
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => version_tag_presenter, :status => :created }
        format.json  { render :json => version_tag_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @version_tag.errors, :status => :unprocessable_entity }
        format.json  { render :json => @version_tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing version_tag with values from a posted XML document
  #
  # ==== Attributes
  #
  # * +name+ - string version_tag (required)
  # * +find_application+ - application name (required)
  # * +find_component+ - component name
  # * +find_environment+ - environment name  
  # * +artifact_url+ - artifact url
  # * +active+ - is active?
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # * Note: find_application can be searched using a prefix if the delimiter '_|_' is used in the application name.  For example, searching for 
  # 'BRPM' will find installed components associated with 'BRPM_|_BMC Release Process Management'.
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<version_xml>' http://0.0.0.0:3000/v1/version_tags/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ version_json }|'  http://[rails_host]/v1/version_tags/[id]?token=[api_token]
  def update
    @version_tag = VersionTag.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @version_tag
        begin
          # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @version_tag.toggle_archive
            @version_tag.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
            # otherwise continue on with a standard update
          elsif params[:version_tag].present?
            success = @version_tag.update_from_params(params[:version_tag])
            @version_tag.properties_values.reload
            @version_tag.reload
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => version_tag_presenter, :status => :accepted }
          format.json  { render :json => version_tag_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @version_tag.errors, :status => :unprocessable_entity }
          format.json  { render :json => @version_tag.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a version_tag by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/version_tags/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/version_tags/[id]?token=[api_token]
  def destroy
    @version_tag = VersionTag.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @version_tag
        
        #
        # FIXME: Mysteriously (not_from_rest) needs to be set before the version tag can be succesfully archived.
        @version_tag.not_from_rest=true
        success = @version_tag.try(:archive) rescue false

        if success
          format.xml { render :xml => version_tag_presenter, :status => :accepted }
          format.json { render :json => version_tag_presenter, :status => :accepted }
        else
          format.xml { render :xml => version_tag_presenter, :status => :precondition_failed }
          format.json { render :json => version_tag_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end
  
  private
    
  # helper for loading the versions presenter
  def version_tags_presenter
    @version_tags_presenter ||= V1::VersionTagsPresenter.new(@version_tags, @template)
  end
    
  # helper for loading the version_tag present
  def version_tag_presenter
    @version_tag_presenter ||= V1::VersionTagPresenter.new(@version_tag, @template)
  end
end
