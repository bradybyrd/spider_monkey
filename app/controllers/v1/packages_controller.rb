class V1::PackagesController < V1::AbstractRestController

  # Returns packages that are active
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  # * +filters+ - Filters criteria for getting subset of packages, can be - "name"
  #
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/packages?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/packages?token=[api_token]
  #

  def index
    @packages = Package.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @packages.blank?
        # to provide a package specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => packages_presenter }
        format.json { render :json => packages_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a package by package id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/packages/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/packages/[id]?token=[api_token]

  def show
    @package = Package.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @package.blank?
        # to provide a package specific and secure representation of an object, wrap it in a presenter
        
        format.xml { render :xml => package_presenter }
        format.json { render :json => package_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end





  # Creates a new package from a posted XML document
  #
  # ==== Attributes
  #
  # Mandatory model attributes
  # * +name+ - string name of the package 
  # 
  # Optional finder methods that lookup and (if found) link this component to the named models
  # * +property_name+ - string name of one existing property OR array of string names for multiple existing properties to be associated with the component
  #
  # Additional optional metadata fields for the package 
  # * +active+ - boolean for active and inactive
  # * +property_ids+ - array of propertied to associate with this package, note +property_name+ will override this
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d '<package><name>New Package</name></package>' http://[host]/v1/packages?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "package": { "name":"New Package" } }' http://[host]/v1/packages/?token=[token]
  #
  def create
    @package = Package.new
    success = false
    respond_to do |format|
      begin
        success = @package.update_attributes(params[:package])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end
      if success
        format.xml  { render :xml => package_presenter, :status => :created }
        format.json  { render :json => package_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @package.errors, :status => :unprocessable_entity }
        format.json  { render :json => @package.errors, :status => :unprocessable_entity }
      end
    end
  end



  # Updates an existing component with values from a posted XML document
  #
  # Mandatory model attributes
  # * +name+ - string name of the component 
  #
  # Optional finder methods that lookup and (if found) link this component to the named models
  # * +property_name+ - string name of one existing property OR array of string names for multiple existing properties to be associated with the component
  # 
  # Additional optional metadata fields for the component 
  # * +active+ - boolean for active and inactive
  # * +property_ids+ - array of propertied to associate with this package, note +property_name+ will override this
  # 
  # Standard REST request attributes
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<package><name>New name</name></package>' http://[host]/v1/packages/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "package": { "name": "new name"} }'  http://[host]/v1/packages/[id]?token=[api_token]   

  def update
    @package = Package.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @package
        begin
          success = @package.update_attributes(params[:package])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => package_presenter, :status => :accepted }
          format.json  { render :json => package_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @package.errors, :status => :unprocessable_entity }
          format.json  { render :json => @package.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a package by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/packages/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/packages/[id]?token=[api_token]
  
  def destroy
    @package = Package.find(params[:id].to_i) rescue nil

    respond_to do |format|
      if @package
        success = @package.deactivate!
        
        if success
          format.xml { render :xml => package_presenter, :status => :accepted }
          format.json { render :json => package_presenter, :status => :accepted }
        else
          format.xml { render :xml => @package.errors, :status => :precondition_failed }
          format.json { render :json => @package.errors, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end




  private

  # helper for loading the package presenter
  def packages_presenter
    @packages_presenter ||= V1::PackagesPresenter.new(@packages, @template)
  end

  # helper for loading the package present
  def package_presenter
    @package_presenter ||= V1::PackagePresenter.new(@package, @template)
  end



end
