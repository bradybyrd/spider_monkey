class V1::RolesController < V1::AbstractRestController

  # Returns roles that are not deleted
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json"
  #              to the last path element
  # * +token+ - your API Token for authentication
  # * +filters+ - keyword:string
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
  # To test this method, insert this url or your valid API key and application
  # host into a browser or http client like wget or curl.  For example:
  #
  #   curl -i -X GET http://[rails_host]/v1/roles.json?token=[api_token]
  #   curl -i -X GET http://[rails_host]/v1/roles.xml?token=[api_token]
  #
  # With filters
  #
  #   curl -i -X GET -d  '<filters><active>true</active></filters>' \
  #     http://[rails_host]/v1/roles.xml?token=[api_token]
  #   curl -i -X POST -d '{ "filters": { "active" : "true" }}' -X GET \
  #     http://[rails_host]/v1/roles.json?token=[api_token] 

  def index
    @roles = Role.filtered(params[:filters])
    respond_to do |format|
      unless @roles.empty?
        format.xml { render xml: roles_presenter }
        format.json { render json: roles_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Returns one role, by id, that is not deleted
  #
  # ==== Attributes
  #
  # * +format+ - be sure to include an accept header or add ".xml" or ".json"
  #              to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 404 Not Found - When no records are found.
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application
  # host into a browser or http client like wget or curl.  For example:
  #
  #   curl -i -X GET http://[rails_host]/v1/roles/[id].json?token=[api_token]
  #   curl -i -X GET http://[rails_host]/v1/roles/[id].xml?token=[api_token]

  def show
    @role = Role.active.where(id: params[:id]).first
    respond_to do |format|
      if @role.present?
        format.xml { render xml: role_presenter }
        format.json { render json: role_presenter }
      else
        format.xml { head :not_found }
        format.json { head :not_found }
      end
    end
  end

  # Soft deletes a role by deactivating them
  #
  # ==== Attributes
  #
  # * +id+ - numerical unique id for record
  # * +format+ - be sure to include an accept header or add ".xml" or ".json"
  #              to the last path element
  # * +token+ - your API Token for authentication
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 404 Not found - When no records are found.
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application
  # host into a browser or http client like wget or curl.  For example:
  #
  #   curl -i -X DELETE http://[rails_host]/v1/roles/[id].xml?token=[api_token]
  #   curl -i -X DELETE http://[rails_host]/v1/roles/[id].json?token=[api_token]

  def destroy
    @role = Role.find_by_id(params[:id].to_i)
    respond_to do |format|
      if @role.present?
        success = @role.deactivate! rescue false
        if success
          format.xml { head :accepted }
          format.json { head :accepted }
        else
          format.xml { render xml: role_presenter, status: :precondition_failed }
          format.json { render json: role_presenter, status: :precondition_failed }
        end
      else
        format.xml  { head :not_found }
        format.json  { head :not_found }
      end
    end
  end

  private

  def roles_presenter
    @roles_presenter ||= V1::RolesPresenter.new(@roles, @template)
  end

  def role_presenter
    @role_presenter ||= V1::RolePresenter.new(@role, @template)
  end
end

