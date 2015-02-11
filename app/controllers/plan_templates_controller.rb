################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class PlanTemplatesController < ApplicationController
  include ArchivableController
  include ObjectStateController

  def index
    authorize! :list, PlanTemplate.new
    @per_page = params[:per_page] || 20
    @page = params[:page] || 1
    @plan_templates = PlanTemplate.unarchived.visible_in_index.name_order.paginate(:page => @page, :per_page => @per_page)
    @archived_plan_templates = PlanTemplate.archived.name_order.paginate(:page => @page, :per_page => @per_page)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @plan_templates }
    end
  end

  def show
    @plan_template = PlanTemplate.find_by_id(params[:id])
    authorize! :inspect, @plan_template

    respond_to do |format|
      if @plan_template
        format.html # show.html.erb
        format.json { render json: @plan_template }
      else
        format.json  { render json: @plan_template.errors, :status => :not_found }
      end
    end
  end

  def new
    @plan_template = PlanTemplate.new
    authorize! :create, @plan_template

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @plan_template }
    end
  end

  def edit
    authorize! :edit, PlanTemplate.new
    @plan_template = find_plan_template

    respond_to do |format|
      format.html
      format.json { render json: @plan_template }
    end
  end

  def create
    @plan_template = PlanTemplate.new(params[:plan_template])
    authorize! :create, @plan_template
    @plan_template.created_by = current_user.id if current_user

    respond_to do |format|
      if @plan_template.save
        format.html { redirect_to @plan_template, :model => PlanTemplate.model_name.human }
        format.json { render json: @plan_template, status: :created, location: @plan_template }
      else
        format.html { render action: "new" }
        format.json { render json: @plan_template.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @plan_template = PlanTemplate.find_by_id(params[:id])
    authorize! :edit, @plan_template

    respond_to do |format|
      if @plan_template && @plan_template.update_attributes(params[:plan_template])
        format.html { redirect_to @plan_template, notice: t('activerecord.notices.updated', :model => PlanTemplate.model_name.human) }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @plan_template.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @plan_template = PlanTemplate.find_by_id(params[:id])
    authorize! :delete, @plan_template

    if !@plan_template
      format.html { redirect_to( plan_templates_path,  :model => PlanTemplate.model_name.human, :id => params[:id]) }
      format.json  { render json: @plan_template.errors, :status => :not_found }
      return
    end
    @plan_template.destroy

    respond_to do |format|
      format.html { redirect_to plan_templates_path, :notice => t('activerecord.notices.deleted', :model => PlanTemplate.model_name.human) }
      format.json { head :ok }
    end
  end

  private

  def find_plan_template
    PlanTemplate.where(id: params[:id]).first || redirect_when_not_found
  end

  def redirect_when_not_found
    # This section is used while accessing a non-existent template from recent page links.
    flash[:error] = I18n.t(:exists_not_or_deleted, model: I18n.t(:'activerecord.models.plan_template'))
    redirect_to(plan_templates_path) && return
  end

end
