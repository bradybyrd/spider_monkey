class V1::PackageInstancesController < V1::AbstractRestController

  # Returns package_instances that are active
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  # * +filters+ - Filters criteria for getting subset of package_instances, can be - "name"
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/package/[package_id]/package_instances?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/package/[package_id]/package_instances?token=[api_token]
  #

  def index
    @package_instances = PackageInstance.filtered(params[:filters]) rescue nil

    respond_to do |format|
      unless @package_instances.blank?
        format.xml { render :xml => package_instances_presenter }
        format.json { render :json => package_instances_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end


  # Returns a package_instance by package_instance id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/package_instances/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/package_instances/[id]?token=[api_token]

  def show
    @package_instance = PackageInstance.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @package_instance.blank?
        # to provide a package specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => package_instance_presenter }
        format.json { render :json => package_instance_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end



  # Creates a new package instance from a posted XML document
  #
  # ==== Attributes
  #
  # Mandatory model attributes
  # * +package_name+ - string name of the parent package
  #
  # Additional optional metadata fields for the package instance
  # * +name+ - will override the generated name from the package.
  # * +active+ - boolean for active and inactive
  # * +reference_ids+ - array of reference ids from the package that will be copied into the package instance
  #        example: <reference_ids type='array'><reference_id>reference id</reference_id></reference_ids>
  #
  # Special property setting accessor that takes key value pairs and overrides the property from package
  # Note: property must already exist AND must be assigned to the package
  # * +properties_with_values+ - hash of key value pairs such as { 'server_url' => 'localhost', 'user_name' => 'admin' }
  #           or <properties_with_value><property_name>property name</property_name><property_value>new value</property_value></properties_with_value></properties_with_values>
  # * +reference_properties_with_values+ - array of property and values for references - these values will override the current value for the property on the reference.
  #                                        Note that the property must already be overridden by the reference
  #           example: <reference_properties_with_values type='array'>
  #                      <reference_properties_with_value>
  #                          <ref_id>54</ref_id>
  #                          <property_name>p1</property_name>
  #                          <property_value>p1fromRest2</property_value>
  #                      </reference_properties_with_value>
  #                    </reference_properties_with_values>
  #                Note that ref_id is the id of the reference on the package.
  #
  # Standard REST request attributes
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d '<package_instance><package_name>Package</package_name></package_instance>' http://[host]/v1/package_instances?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "package_instance": { "package_name":"Package" } }' http://[host]/v1/package_instances/?token=[token]
  #
  def create
    @package_instance = PackageInstance.new
    success = false
    respond_to do |format|
      begin
        PackageInstanceCreate.call( @package_instance, params[:package_instance] )
        success = @package_instance.errors.blank?
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end
      if success
        ## This is needed to get the updates to properties after the save
        if @package_instance.errors.blank? && @package_instance.persisted?
          @package_instance.reload
        end
        format.xml  { render :xml => package_instance_presenter, :status => :created }
        format.json  { render :json => package_instance_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @package_instance.errors, :status => :unprocessable_entity }
        format.json  { render :json => @package_instance.errors, :status => :unprocessable_entity }
      end
    end
  end


  # Updates an existing installed_component with values from a posted XML document
  #
  # ==== Attributes
  #
  # Note: you must indicate all three mandatory fields to create an installed component
  #
  # Special property setting accessor that takes key value pairs and overrides the property from package
  # Note: property must already exist AND must be assigned to the package
  # * +properties_with_values+ - hash of key value pairs such as { 'server_url' => 'localhost', 'user_name' => 'admin' }
  #           or <properties_with_value><property_name>property name</property_name><property_value>new value</property_value></properties_with_value></properties_with_values>
  # * +reference_ids+ - if specified, array of reference ids from the package that will be copied into the package instance.
  #                   Note that existing instance references will be deleted if not in this list.
  #        example: <reference_ids type='array'><reference_id>reference id</reference_id></reference_ids>
  # * +reference_properties_with_values+ - array of property and values for references - these values will override the current value for the property on the reference.
  #                                        Note that the property must already be overridden by the reference
  #           example: <reference_properties_with_values type='array'>
  #                      <reference_properties_with_value>
  #                          <ref_id>54</ref_id>
  #                          <property_name>p1</property_name>
  #                          <property_value>p1fromRest2</property_value>
  #                      </reference_properties_with_value>
  #                    </reference_properties_with_values>
  #                Note that ref_id is the id of the reference on the package.
  #
  # Additional optional metadata fields for the installed component
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<package_instance>attributes</package_instance>' http://0.0.0.0:3000/v1/package_instances/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ package_instance_json }|'  http://[rails_host]/v1/package_instances/[id]?token=[api_token]

  def update
    @package_instance = PackageInstance.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @package_instance
        begin
          success = PackageInstanceUpdate.call(@package_instance,params[:package_instance]) && @package_instance.errors.blank?
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          ## This is needed to get the updates to properties and references after the save
          @package_instance.reload

          ## This is needed to get the updates to properties after the save
          format.xml  { render :xml => package_instance_presenter, :status => :accepted }
          format.json  { render :json => package_instance_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @package_instance.errors, :status => :unprocessable_entity }
          format.json  { render :json => @package_instance.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end



  # Soft deletes a package_instance by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/package_instances/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/package_instances/[id]?token=[api_token]

  def destroy
    @package_instance = PackageInstance.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @package_instance
        success = @package_instance.try(:deactivate!) rescue false

        if success
          format.xml { render :xml => package_instance_presenter, :status => :accepted }
          format.json { render :json => package_instance_presenter, :status => :accepted }
        else
          format.xml { render :xml => package_instance_presenter, :status => :precondition_failed }
          format.json { render :json => package_instance_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  def package_instance_presenter
    @package_instance_presenter ||= V1::PackageInstancePresenter.new(@package_instance, @template)
  end

  def package_instances_presenter
    @package_instances_presenter ||= V1::PackageInstancesPresenter.new(@package_instances, @template)
  end
end
