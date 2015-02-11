class V1::ReferencesController < V1::AbstractRestController
  # Creates a new package reference
  #
  # ==== Attributes
  #
  # Mandatory fields
  # * +name+ - string name of the reference
  # * +server_id+ - string id of the associated server
  # * +package_id+ - string id of the parent package
  # * +url+ - string of the url to the reference
  #
  # Note: you must indicate all four mandatory fields to create a reference
  #
  # Special property setting accessor that takes key value pairs and attaches them to the reference
  # Note: property must already exist AND must be assigned to the reference
  # * +properties_with_values+ - hash of key value pairs such as { 'server_url' => 'localhost', 'user_name' => 'admin' }
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 422 Unprocessable entity - When validation fails, objects and errors are returned.
  #
  # ==== Examples=
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml"  -H "Content-type: text/xml" -X POST -d "<reference><name>Reference</name><server_id>2</server_id><package_id>123</package_id><url>/path/to/file</url></reference>" http://[rails_host]/v1/references?token=[...your token ...]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "reference": { "name" : "Reference", "server_id" : "123", "package_id" : "1234", "url" : "/path/to/file" }}' http://[rails_host]/v1/references/?token=[api_token]

  def create
    @reference = Reference.new
    success = false
    respond_to do |format|
      begin
        success = @reference.update_attributes(reference_params)
      rescue Exception => e
        @exception = { message: e.message, backtrace: e.backtrace.inspect }
      end
      if success
        format.xml { render xml: reference_presenter, status: :created }
        format.json { render json: reference_presenter, status: :created }
      elsif @exception
        format.xml { render xml: @exception, status: :internal_server_error }
        format.json { render json: @exception, status: :internal_server_error }
      else
        format.xml{ render xml: @reference.errors, status: :unprocessable_entity }
        format.json { render json: @reference.errors, status: :unprocessable_entity }
      end
    end
  end

  # Updates an existing reference with values from a posted document
  #
  # ==== Attributes
  #
  # * +name+ - string name of the reference
  # * +server_id+ - string id of the associated server
  # * +package_id+ - string id of the parent package
  # * +url+ - string of the url to the reference
  #
  # Note: you must indicate all four mandatory fields to create a reference
  #
  # Special property setting accessor that takes key value pairs and attaches them to the reference
  # Note: property must already exist AND must be assigned to the reference
  # * +properties_with_values+ - hash of key value pairs such as { 'server_url' => 'localhost', 'user_name' => 'admin' }
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 422 Unprocessable entity - When validation fails, objects and errors are returned.
  #
  # ==== Examples=
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml"  -H "Content-type: text/xml" -X PUT -d "<reference><name>Reference</name><server_id>2</server_id><package_id>123</package_id><url>/path/to/file</url></reference>" http://[rails_host]/v1/references/[reference_id]?token=[...your token ...]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "reference": { "name" : "Reference", "server_id" : "123", "package_id" : "1234", "url" : "/path/to/file" }}' http://[rails_host]/v1/references/[reference_id]?token=[api_token]

  def update
    @reference = Reference.find(params[:id])
    success = false
    respond_to do |format|
      begin
        success = @reference.update_attributes(reference_params)
      rescue Exception => e
        @exception = { message: e.message, backtrace: e.backtrace.inspect }
      end
      if success
        format.xml { render xml: reference_presenter, status: :accepted }
        format.json { render json: reference_presenter, status: :accepted }
      elsif @exception
        format.xml { render xml: @exception, status: :internal_server_error }
        format.json { render json: @exception, status: :internal_server_error }
      else
        format.xml{ render xml: @reference.errors, status: :unprocessable_entity }
        format.json { render json: @reference.errors, status: :unprocessable_entity }
      end
    end
  end

  # Deletes a reference
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/references/[reference_id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/references/[reference_id]?token=[api_token]

  def destroy
    @reference = Reference.find(params[:id]) rescue nil
    respond_to do |format|
      if @reference
        success = @reference.try(:destroy) rescue false
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => reference_presenter, :status => :precondition_failed }
          format.json { render :json => reference_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  def reference_params
    params[:reference]
  end

  def reference_presenter
    @reference_presenter ||= V1::ReferencePresenter.new(@reference, @template)
  end
end
