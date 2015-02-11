class V1::UsersController < V1::AbstractRestController

  # Returns users that are not deleted nor archived
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  # * +filters+ - active:boolean, inactive:boolean, root:boolean,
  #               keyword:string (covers login, first name, last name,
  #               full name ('John Smith'), reverse name ('Smith John'))
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/users?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/users?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><active>true</active></filters>' http://[rails_host]/v1/users?token=[api_token]
  #
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "active" : 'true' }}' -X GET http://[rails_host]/v1/users?token=[api_token]
  def index
    @users = User.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @users.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => users_presenter }
        format.json { render :json => users_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a user by user id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/users/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/users/[id]?token=[api_token]
  def show
    @user = User.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @user.present?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => user_presenter }
        format.json { render :json => user_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new user from a posted XML document
  #
  # ==== Attributes
  #
  # * +id+ - numerical unique id for record to be updated
  # * +first_name+ - string first name of the user (required)
  # * +last_name+ - string last name of the user (required)
  # * +password+ - string password of the user (required)
  # * +password_confirmation+ - string password confirmation of the user (required)
  # * +email+ - string email address for the user (required)
  # * +contact_number+ - string contact number for the user (optional)
  # * +max_allocation+ - integer max allocation value for the user (optional)
  # * +employment_type+ - string value (permanent, contractor) for the user (optional)
  # * +time_zone+ - string value ('Central Time (US & Canada)') for the user (optional)
  # * +first_day_on_calendar+ - integer (1-7) for calendar first day for the user (optional)
  # * +user ... + - other valid user fields
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Accepts Nested Attributes for Creation and Update of Associated Objects
  #
  # * +user with release_attributes - this will accept nested attributes for an existing or a new release
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<user><name>XML User</name><release_name>Sample Release</release_name>  <user_template>Sample Deploy Template</user_template></user>'  http://0.0.0.0:3000/v1/users?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d \n '{ "user": { "name" : "JSONRenamedUser", "user_template_id":1}}'  http://[rails_host]/v1/users?token=[api_token]
  #
  # Create a new user and a new associated release
  #
  #    curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d '<user><name>XML User 3:05PM</name><release_attributes><name>Brand New Release 2</name></release_attributes><user_template_id>1</user_template_id></user>' http://0.0.0.0:3000/v1/users?token=[token]

  def create
    @user = User.new
    respond_to do |format|
      begin
        success = @user.update_attributes(params[:user])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => user_presenter, :status => :created }
        format.json  { render :json => user_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        format.json  { render :json => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing user with values from a posted XML document
  #
  # ==== Attributes
  #
  # * +first_name+ - string first name of the user (required)
  # * +last_name+ - string last name of the user (required)
  # * +password+ - string password of the user (required)
  # * +password_confirmation+ - string password confirmation of the user (required)
  # * +email+ - string email address for the user (required)
  # * +contact_number+ - string contact number for the user (optional)
  # * +max_allocation+ - integer max allocation value for the user (optional)
  # * +employment_type+ - string value (permanent, contractor) for the user (optional)
  # * +time_zone+ - string value ('Central Time (US & Canada)') for the user (optional)
  # * +first_day_on_calendar+ - integer (1-7) for calendar first day for the user (optional)
  # * +user ... + - other valid user fields
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<user><name>XML User</name><release_name>Sample Release</release_name></user>' http://0.0.0.0:3000/v1/users/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "user": { "name" : "JSONRenamedUser", "description":"JSON Hello"}}'  http://[rails_host]/v1/users/[id]?token=[api_token]
  def update
    @user = User.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @user
        begin
          success = @user.update_attributes(params[:user])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => user_presenter, :status => :accepted }
          format.json  { render :json => user_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
          format.json  { render :json => @user.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a user by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/users/[id]?token=[api_token]
  #
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/users/[id]?token=[api_token]
  def destroy
    @user = User.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @user
        success = @user.try(:deactivate!) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => user_presenter, :status => :precondition_failed }
          format.json { render :json => user_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the users presenter
  def users_presenter
    @users_presenter ||= V1::UsersPresenter.new(@users, @template)
  end

  # helper for loading the user present
  def user_presenter
    @user_presenter ||= V1::UserPresenter.new(@user, @template)
  end
end
