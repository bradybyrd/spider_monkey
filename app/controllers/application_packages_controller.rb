################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class ApplicationPackagesController < ApplicationController
  before_filter :find_application_package, only: [:edit, :edit_property_values, :update_property_values]

  def update_all
    @app = find_app
    authorize! :add_remove_package, @app

    # If not packages are selected a request with no app parameter is supplied
    params[:app] = {} unless params[:app]
    params[:app][:package_ids] = [] unless params[:app][:package_ids]

    @app.package_ids = (params[:app][:package_ids]) || []
    @app.save

    redirect_to edit_app_path(:page => params[:page], :key => params[:key], :id => @app.id, :show_package_tab => true )
  end

  def edit
    redirect_to edit_app_path(@application_package.app, :show_package_tab => true )
  end

  def edit_property_values
    authorize! :edit_properties, @application_package
    render template: 'properties/edit_property_values', locals: { object: @application_package }, layout: false
  end

  def update_property_values
    authorize! :edit_properties, @application_package

    change_property_values!
    redirect_to edit_app_path(@application_package.app, show_package_tab: true)
  end

  protected

  def find_application_package
    @application_package = ApplicationPackage.find(params[:id])
  end

  def find_app
    App.find(params[:app_id])
  end

  private

  def change_property_values!
    Property.where(id: params[:property_values].keys).each do |property|
      property.update_value_for_object(@application_package, params[:property_values][property.id.to_s])
    end
  end

end

