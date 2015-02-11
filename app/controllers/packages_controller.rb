################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PackagesController < ApplicationController
  include ControllerSoftDelete
  include MultiplePicker
  include TableSorter

  helper_method :sort_direction, :sort_column

  before_filter :get_property_ids, only: [:update]

  def index
    authorize! :list, Package.new
    accessible_packages = current_user.accessible_packages
    @active_packages = sort(accessible_packages.active)
    @inactive_packages = sort(accessible_packages.inactive)
    if search_keyword.present?
      @active_packages = @active_packages.search_by_ci("name", search_keyword)
      @inactive_packages = @inactive_packages.search_by_ci("name", search_keyword)
    end
    @total_records = @active_packages.length
    if @active_packages.blank? && @inactive_packages.blank?
      flash.now[:error] = "No Package found"
    end
    @active_packages = @active_packages.paginate(page: page)
    @inactive_packages = @inactive_packages.paginate(page: inactive_page)
    render partial: "index", layout: false if request.xhr?
  end

  def new
    @package = Package.new
    authorize! :create, @package
  end

  def edit
    @package = find_package
    authorize! :edit, @package
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "No Package found"
    redirect_to :back
  end

  def create
    @package = Package.new(params[:package])
    authorize! :create, @package
    @package.not_from_rest =  true
    if @package.save
      flash[:notice] = 'Package was successfully created.'
      redirect_to edit_package_path( :id => @package.id )
    else
      render :action => "new"
    end
  end

  def update
    @package = find_package
    authorize! :edit, @package
    @package.not_from_rest =  true
    if @package.update_attributes(params[:package])
      flash[:notice] = 'Package was successfully updated.'
      if ( params[:auto_submit] == 'y' )
        render :action => "edit"
      else
        redirect_to packages_path(page: params[:page], key: params[:key])
      end
    else
      render :action => "edit"
    end
  end

  def destroy
    @package = find_package
    authorize! :delete, @package
    @package.destroy

    redirect_to packages_path(page: params[:page], key: params[:key])
  end

  private

  def sort_column_is_safe?
    Package.column_names.include?(params[:sort])
  end

  def sort_column_prefix
    if OracleAdapter
      "#{Package.table_name}."
    else
      ""
    end
  end

  def inactive_page
    params[:inactive_page]
  end

  def page
    if params[:page].to_i > 0
      params[:page]
    else
      1
    end
  end

  def search_keyword
    params[:key]
  end

  def find_package
    Package.find params[:id]
  end

  def get_property_ids
    ## If we have no properties this means the user removed all properties
    if ( params.has_key?( :auto_submit ) and not params[:package].has_key?(:property_ids) )
      params[:package][:property_ids] = []
    end
  end
end

