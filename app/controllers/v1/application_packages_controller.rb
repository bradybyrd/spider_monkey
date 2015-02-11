################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::ApplicationPackagesController < V1::AbstractRestController
  # Associates a package to an application
  #
  # ==== Attributes
  #
  # * +app_id+ - string id of the app
  # * +package_id+ - string id of the package to associate with the app
  #
  # Special property setting accessor that takes key value pairs and attaches
  # them to the associated application package. Note: property must already
  # exist AND must be assigned to the reference
  # * +properties_with_values+ - hash of key value pairs such as { 'server_url' => 'localhost', 'user_name' => 'admin' }
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
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X POST -d  '<application_package><app_id>1</app_id><package_id>1</package_id></application_package>'  http://[rails_host]/v1/application_packages?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X POST -d \n '{ "application_package": { "app_id" : "1", "package_id" : "1" }}'  http://[rails_host]/v1/application_packages?token=[api_token]
  def create
    new_app_package = ApplicationPackage.new(
      app_id: app_id,
      package_id: package_id,
      properties_with_values: properties_with_values
    )
    new_app_package.save
    render_app_package(new_app_package, :created)
  end

  # Updates overridden properties for an application package
  #
  # ==== Attributes
  #
  # * +app_id+ - string id of the app
  # * +package_id+ - string id of the package
  #
  # Note: if there is no application package for the passed in app_id and
  # package_id the API will return a 404
  #
  # Special property setting accessor that takes key value pairs and attaches
  # them to the associated application package. Note: property must already
  # exist AND must be assigned to the reference
  # * +properties_with_values+ - hash of key value pairs such as { 'server_url' => 'localhost', 'user_name' => 'admin' }
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 404 Not found - When the application package for the passed in app and package is not found
  # * ERROR 422 Unprocessable entity - When validation fails
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X PUT -d  '<application_package><app_id>1</app_id><package_id>1</package_id></application_package>'  http://[rails_host]/v1/application_packages?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X PUT -d \n '{ "application_package": { "app_id" : "1", "package_id" : "1" }}'  http://[rails_host]/v1/application_packages?token=[api_token]
  def update
    if app_package.present?
      app_package.properties_with_values = properties_with_values
      app_package.save
      render_app_package(app_package, :accepted)
    else
      head :not_found
    end
  end

  # Removes the association between an app and a package
  #
  # ==== Attributes
  #
  # * +app_id+ - string id of the app
  # * +package_id+ - string id of the package
  #
  # Note: if there is no application package for the passed in app_id and
  # package_id the API will return a 404
  #
  # ==== Raises
  #
  # * ERROR 403 Forbidden - When the token is invalid.
  # * ERROR 404 Not found - When the application package for the passed in app and package is not found
  #
  # ==== Examples
  #
  # To test this method, insert this url or your valid API key and application host into
  # a browser or http client like wget or curl.  For example:
  #
  #   curl -i -H "accept: text/xml" -H "Content-type: text/xml" -X DELETE -d  '<application_package><app_id>1</app_id><package_id>1</package_id></application_package>'  http://[rails_host]/v1/application_packages?token=[api_token]
  #   curl -i -H "accept: application/json" -H "Content-type: application/json" -X DELETE -d \n '{ "application_package": { "app_id" : "1", "package_id" : "1" }}'  http://[rails_host]/v1/application_packages?token=[api_token]
  def destroy
    if app_package.present?
      app_package.destroy
      head :accepted
    else
      head :not_found
    end
  end

  private

  def render_app_package(app_package, status)
    respond_to do |format|
      if app_package.errors.empty?
        format.xml { render xml: application_package_presenter(app_package), status: status }
        format.json { render json: application_package_presenter(app_package), status: status }
      else
        format.xml{ render xml: app_package.errors, status: :unprocessable_entity }
        format.json { render json: app_package.errors, status: :unprocessable_entity }
      end
    end
  end

  def app_package
    @app_package ||= ApplicationPackage.where(
      app_id: app_id,
      package_id: package_id
    ).first
  end

  def application_package_presenter(application_package)
    @application_package_presenter ||=
      V1::ApplicationPackagePresenter.new(application_package, @template)
  end

  def app_id
    params[:application_package][:app_id]
  end

  def package_id
    params[:application_package][:package_id]
  end

  def properties_with_values
    params[:application_package][:properties_with_values]
  end
end
