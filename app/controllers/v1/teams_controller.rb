class V1::TeamsController < V1::AbstractRestController
  
  # Returns teams that are active by default
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  # * +filters+ - active:boolean, inactive:boolean, name:string
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/teams?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/teams?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><active>true</active></filters>' http://[rails_host]/v1/teams?token=[api_token]
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "active" : 'true' }}' -X GET http://[rails_host]/v1/teams?token=[api_token] 
  def index
    @teams = Team.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @teams.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => teams_presenter }
        format.json { render :json => teams_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a team by team id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/teams/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/teams/[id]?token=[api_token]
  def show
    @team = Team.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @team.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        
        format.xml { render :xml => team_presenter }
        format.json { render :json => team_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new team from a post request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the team (required, unique)
  # * +user_id+ - integer of an existing user id (optional)
  # * +active+ - boolean for active (option, default true)
  # * +app_ids+ - array of integer ids for related applications
  # * +group_ids+ - array of integer ids for related groups
  # * +user_ids+ - array of integer ids for related users
  # * +format+ - be sure to include an accept header or add ".xml" or ".json" to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Accepts Nested Attributes for Creation and Update of Associated Objects
  #
  # * +team with release_attributes - this will accept nested attributes for an existing or a new release
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<team><name>XML Team</name></team>'  http://[rails_host]/v1/teams?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d \n '{ "team": { "name" : "JSONRenamedTeam" }}'  http://[rails_host]/v1/teams?token=[api_token]
  
  def create
    @team = Team.new
    respond_to do |format|
      begin
        success = @team.update_attributes(params[:team])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => team_presenter, :status => :created }
        format.json  { render :json => team_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @team.errors, :status => :unprocessable_entity }
        format.json  { render :json => @team.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing team with values from a PUT request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the team (required, unique)
  # * +user_id+ - integer of an existing user id (optional)
  # * +app_ids+ - array of integer ids for related applications
  # * +group_ids+ - array of integer ids for related groups
  # * +user_ids+ - array of integer ids for related users
  # * +active+ - boolean for active (option, default true)  
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<team><name>XML Team</name><active>false</active></team>' http://[rails_host]/v1/teams/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "team": { "name" : "JSONRenamedTeam", "user_id": 1 }}'  http://[rails_host]/v1/teams/[id]?token=[api_token] 
  def update
    @team = Team.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @team
        begin
          success = @team.update_attributes(params[:team])
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => team_presenter, :status => :accepted }
          format.json  { render :json => team_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @team.errors, :status => :unprocessable_entity }
          format.json  { render :json => @team.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a team by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/teams/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/teams/[id]?token=[api_token]
  def destroy
    @team = Team.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @team
        success = @team.try(:deactivate!) rescue false
        
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => team_presenter, :status => :precondition_failed }
          format.json { render :json => team_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end
  
  private

  # helper for loading the teams presenter
  def teams_presenter
    @teams_presenter ||= V1::TeamsPresenter.new(@teams, @template)
  end
    
  # helper for loading the team present  
  def team_presenter
    @team_presenter ||= V1::TeamPresenter.new(@team, @template)
  end
end
