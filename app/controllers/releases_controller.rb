################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ReleasesController < ApplicationController
  include ArchivableController

  def index
    @per_page = params[:per_page] || 20
    @page = params[:page] || 1
    @releases = Release.unarchived.name_order.paginate(:page => @page, :per_page => @per_page)
    @archived_releases = Release.archived.name_order.paginate(:page => @page, :per_page => @per_page)
  end

  def new
    @release = Release.new
    authorize! :create, @release
  end

  def edit
    @release = find_release
    authorize! :edit, @release
  end

  def create
    @release = Release.new(params[:release])
    authorize! :create, @release

    if @release.save
      flash[:notice] = 'Release was successfully created.'
      redirect_to releases_path
    else
      render :action => "new"
    end
  end

  def update
    @release = find_release
    authorize! :edit, @release
    @original_title = @release.name
    if @release.update_attributes(params[:release])
      flash[:notice] = 'Release was successfully updated.'
      redirect_to releases_path
    else
      render :action => "edit"
    end
  end

  def show
    @release = find_release
    authorize! :list, @release
    redirect_to  edit_release_path(@release)
  end

  def destroy
    @release = find_release
    authorize! :delete, @release
    @release.destroy

    redirect_to releases_path, notice: t('activerecord.notices.deleted', model: Release.model_name.human)
  end

  def reorder
    release = find_release
    authorize! :edit, release
    release.update_attributes(params[:release])

    render :partial => 'releases/release', :locals => { :release => release, :archived => false }
  end

  protected
    def find_release
      begin
        Release.find params[:id]
      rescue ActiveRecord::RecordNotFound
        flash[:error] = "Release you are trying to access either does not exist or has been deleted"
        redirect_to(releases_path) && return
      end
    end
end
