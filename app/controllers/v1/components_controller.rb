class V1::ComponentsController < V1::AbstractRestController

  # Returns components that are active
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  # * +filters+ - Filters criteria for getting subset of components, can be - "name", "app_name", "property_name"  
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/components?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/components?token=[api_token]
  #

  def index
    @components = Component.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @components.blank?
        # to provide a component specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => components_presenter }
        format.json { render :json => components_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a component by component id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/components/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/components/[id]?token=[api_token]

  def show
    @component = Component.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @component.blank?
        # to provide a component specific and secure representation of an object, wrap it in a presenter
        
        format.xml { render :xml => component_presenter }
        format.json { render :json => component_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end


  # Creates a new component from a posted XML document
  #
  # ==== Attributes
  #
  # Mandatory model attributes
  # * +name+ - string name of the component 
  # 
  # Optional finder methods that lookup and (if found) link this component to the named models
  # * +app_name+ - string name of one application OR array of string names for multiple applications
  # * +property_name+ - string name of one existing property OR array of string names for multiple existing properties to be associated with the component
  #
  # * Note: app_name can be searched using a prefix if the delimiter '_|_' is used in the application name.  For example, searching for 
  # 'BRPM' will find installed components associated with 'BRPM_|_BMC Release Process Management'.
  #  
  # Additional optional metadata fields for the component 
  # * +active+ - boolean for active and inactive
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d '<component><name>New Component</name></component>' http://[host]/v1/components?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "component": { "name":"New Component" } }' http://[host]/v1/components/?token=[token]
  #
  # Creating a property with the component
  # 
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{ "component": { "name":"New Component", "app_name":"BRPM", "property_name":["server_url","other_existing_property"] } }' http://[host]/v1/components/?token=[token]
  #
  #
  def create
    @component = Component.new
    success = false
    respond_to do |format|
      begin
        success = @component.update_attributes(params[:component])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end
      if success
        format.xml  { render :xml => component_presenter, :status => :created }
        format.json  { render :json => component_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @component.errors, :status => :unprocessable_entity }
        format.json  { render :json => @component.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing component with values from a posted XML document
  #
  # Mandatory model attributes
  # * +name+ - string name of the component 
  # 
  # Optional finder methods that lookup and (if found) link this component to the named models
  # * +app_name+ - string name of one application OR array of string names for multiple applications
  # * +property_name+ - string name of one existing property OR array of string names for multiple existing properties to be associated with the component
  #
  # * Note: app_name can be searched using a prefix if the delimiter '_|_' is used in the application name.  For example, searching for 
  # 'BRPM' will find installed components associated with 'BRPM_|_BMC Release Process Management'.
  #  
  # Additional optional metadata fields for the component 
  # * +active+ - boolean for active and inactive
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<component><name>New name</name></component>' http://[host]/v1/components/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "component": { "name": "new name"} }'  http://[host]/v1/components/[id]?token=[api_token]   

  def update
    @component = Component.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @component
        begin
          success = @component.update_attributes(params[:component])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => component_presenter, :status => :accepted }
          format.json  { render :json => component_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @component.errors, :status => :unprocessable_entity }
          format.json  { render :json => @component.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a component by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/components/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/components/[id]?token=[api_token]
  
  def destroy
    @component = Component.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @component
        success = @component.try(:deactivate!) rescue false
        
        if success
          format.xml { render :xml => component_presenter, :status => :accepted }
          format.json { render :json => component_presenter, :status => :accepted }
        else
          format.xml { render :xml => component_presenter, :status => :precondition_failed }
          format.json { render :json => component_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end


  private
    
  # helper for loading the componets presenter
  def components_presenter
    @components_presenter ||= V1::ComponentsPresenter.new(@components, @template)
  end
    
  # helper for loading the component present
  def component_presenter
    @component_presenter ||= V1::ComponentPresenter.new(@component, @template)
  end


end
