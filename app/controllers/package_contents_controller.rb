################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PackageContentsController < ApplicationController

  # mixin to add an archive, unarchive action set
  include ArchivableController

  after_filter :update_abbreviations, :only => [:create, :update]

  def index
    @per_page = params[:per_page] || 20
    @page = params[:page] || 1
    @package_contents = PackageContent.unarchived.in_order.paginate(:page => @page, :per_page => @per_page)
    @archived_package_contents = PackageContent.archived.in_name_order.paginate(:page => @page, :per_page => @per_page)
  end

  def new
    @package_content = PackageContent.new
    authorize! :create, @package_content
  end

  def edit
    begin
      @package_content = find_package_content
      authorize! :edit, @package_content
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Package Content you are trying to access either does not exist or has been deleted"
      redirect_to(package_contents_path) && return
    end
  end

  def create
    @package_content = PackageContent.new(params[:package_content])
    authorize! :create, @package_content

    if @package_content.save
      flash[:notice] = 'Package Content was successfully created.'
      redirect_to package_contents_path
    else
      render :action => "new"
    end
  end

  def update
    @package_content = find_package_content
    authorize! :edit, @package_content

    if @package_content.update_attributes(params[:package_content])
      flash[:notice] = 'Package Content was successfully updated.'
      redirect_to package_contents_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @package_content = find_package_content
    authorize! :delete, @package_content
    @package_content.destroy

    redirect_to package_contents_path, notice: t('activerecord.notices.deleted', model: PackageContent.model_name.human)
  end

  def reorder
    package_content = find_package_content
    authorize! :edit, @package_content
    package_content.update_attributes(params[:package_content])

    render :partial => 'package_contents/package_content', :locals => { :package_content => package_content,:archived => false }
  end

  protected
    def find_package_content
      PackageContent.find params[:id]
    end

    def update_abbreviations
      PackageContent.update_abbreviations!
    end

end
