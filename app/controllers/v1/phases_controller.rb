class V1::PhasesController < V1::AbstractRestController
  # Returns phases that are unarchived by default
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/phases?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/phases?token=[api_token]
  #
  # With filters
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X GET -d  '<filters><name>Sample Phase</name></filters>' http://[rails_host]/v1/phases?token=[api_token]
  #   curl -i -H "accept: application/json"  -H "Content-type: application/json"  -X POST -d '{ "filters": { "name" : 'Sample Phase' }}' -X GET http://[rails_host]/v1/phases?token=[api_token]
  def index
    @phases = Phase.in_order.filtered(params[:filters]) rescue nil
    respond_to do |format|
      unless @phases.try(:empty?)
        # to provide a version specific and secure representation of an object, wrap it in a presenter
        format.xml { render :xml => phases_presenter }
        format.json { render :json => phases_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns a phase by phase id
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
  #   curl -i -H "accept: text/xml" -X GET http://[rails_host]/v1/phases/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X GET http://[rails_host]/v1/phases/[id]?token=[api_token]
  def show
    @phase = Phase.find(params[:id].to_i) rescue nil
    respond_to do |format|
      unless @phase.blank?
        # to provide a version specific and secure representation of an object, wrap it in a presenter

        format.xml { render :xml => phase_presenter }
        format.json { render :json => phase_presenter }
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Creates a new phase from a post request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the phase (required, unique)
  # * +runtime_phase_ids+ - array of integer ids for related runtime phases
  # * +step_ids+ - array of integer ids for related step ids
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<phase><name>XML Phase 2</name></phase>'  http://[rails_host]/v1/phases?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d '{"phase": {"name":"Phase New" }}'  http://[rails_host]/v1/phases?token=[api_token]

  def create
    @phase = Phase.new
    respond_to do |format|
      begin
        success = @phase.update_attributes(params[:phase])
      rescue Exception => e
        @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
      end

      if success
        format.xml  { render :xml => phase_presenter, :status => :created }
        format.json  { render :json => phase_presenter, :status => :created }
      elsif @exception
        format.xml  { render :xml => @exception, :status => :internal_server_error }
        format.json  { render :json => @exception, :status => :internal_server_error }
      else
        format.xml  { render :xml => @phase.errors, :status => :unprocessable_entity }
        format.json  { render :json => @phase.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Updates an existing phase with values from a PUT request
  #
  # ==== Attributes
  #
  # * +name+ - string name of the phase (required, unique)
  # * +runtime_phase_ids+ - array of integer ids for related runtime phases
  # * +step_ids+ - array of integer ids for related step ids
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d '<phase><name>XML Phase Rename</name></phase>' http://[rails_host]/v1/phases/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d '{ "phase": { "name" : "JSON Phase Rename" }}'  http://[rails_host]/v1/phases/[id]?token=[api_token]
  def update
    @phase = Phase.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @phase
        begin
          # check for special commands like toggle archive
          if param_present_and_true?(:toggle_archive)
            success = @phase.toggle_archive
            @phase.errors.add(:toggle_archive, 'Archive action could not be completed.') unless success
            # otherwise continue on with a standard update  
          elsif params[:phase].present?
            success = @phase.update_attributes(params[:phase])
          end
        rescue Exception => e
          @exception = { :message => e.message, :backtrace => e.backtrace.inspect }
        end

        if success
          format.xml  { render :xml => phase_presenter, :status => :accepted }
          format.json  { render :json => phase_presenter, :status => :accepted }
        elsif @exception
          format.xml  { render :xml => @exception, :status => :internal_server_error }
          format.json  { render :json => @exception, :status => :internal_server_error }
        else
          format.xml  { render :xml => @phase.errors, :status => :unprocessable_entity }
          format.json  { render :json => @phase.errors, :status => :unprocessable_entity }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  # Soft deletes a phase by deactivating them
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
  #   curl -i -H "accept: text/xml" -X DELETE http://[rails_host]/v1/phases/[id]?token=[api_token]
  #   curl -i -H "accept: application/json" -X DELETE http://[rails_host]/v1/phases/[id]?token=[api_token]
  def destroy
    @phase = Phase.find(params[:id].to_i) rescue nil
    respond_to do |format|
      if @phase
        success = @phase.try(:destroy) rescue false

        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render :xml => phase_presenter, :status => :precondition_failed }
          format.json { render :json => phase_presenter, :status => :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  # helper for loading the phases presenter
  def phases_presenter
    @phases_presenter ||= V1::PhasesPresenter.new(@phases, @template)
  end

  # helper for loading the phase present
  def phase_presenter
    @phase_presenter ||= V1::PhasePresenter.new(@phase, @template)
  end
end
