################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class WorkTasksController < ApplicationController
  include ArchivableController

  def index
    authorize! :list, WorkTask.new

    # order scopes have to come before active or inactive or they get overwritten --Confirm for present scenario(Sourabh)
    @per_page = params[:per_page] || 20
    @page = params[:page] || 1
    @work_tasks = WorkTask.in_order.unarchived.paginate(:page => @page, :per_page => @per_page)
    @archived_work_tasks = WorkTask.in_order.archived.paginate(:page => @page, :per_page => @per_page)
  end

  def new
    @work_task = WorkTask.new
    authorize! :create, @work_task
  end

  def edit
    @work_task = find_work_task
    authorize! :edit, @work_task
  end

  def create
    @work_task = WorkTask.new(params[:work_task])
    authorize! :create, @work_task

    if @work_task.save
      flash[:notice] = I18n.t(:'activerecord.notices.created', model: I18n.t(:'activerecord.models.work_task'))
      redirect_to work_tasks_path
    else
      render :action => 'new'
    end
  end

  def update
    @work_task = find_work_task
    authorize! :edit, @work_task

    if @work_task.update_attributes(params[:work_task])
      flash[:notice] = I18n.t(:'activerecord.notices.updated', model: I18n.t(:'activerecord.models.work_task'))
      redirect_to work_tasks_path
    else
      render :action => 'edit'
    end
  end

  def destroy
    @work_task = find_work_task
    authorize! :delete, @work_task

    if @work_task.destroy
      flash[:notice] = I18n.t(:'activerecord.notices.deleted', model: I18n.t(:'activerecord.models.work_task'))
    end

    redirect_to work_tasks_path
  end

  def reorder
    work_task = find_work_task
    work_task.update_attributes(params[:work_task])

    render :partial => 'work_tasks/work_task', :locals => {:work_task => work_task, :archived => false}
  end

  protected

  def find_work_task
    begin
      WorkTask.find params[:id]
    rescue ActiveRecord::RecordNotFound
      flash[:error] = I18n.t(:'activerecord.notices.not_found', model: I18n.t(:'work_task.work_task'))
      redirect_to :back
    end
  end

end
